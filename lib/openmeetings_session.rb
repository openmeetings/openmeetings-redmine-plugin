# Openmeetings plugin for Redmine
# Copyright (C) 2013 Artyom Horuzhenko
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
require 'soap/rpc/driver'
require 'wsdl/importer'

class OpenmeetingsSession
  
  class OpenmeetingsError < RuntimeError
    
    attr_reader :error_code, :message, :type
    
    def initialize(remote_error_object)
      @error_code = remote_error_object.errorId
      @message = remote_error_object.errmessage;
      @type = remote_error_object.errortype;
    end
    
  end
  
  EXTERNAL_TYPE = "redmine"
  
  attr_reader :base_url, :username, :userpass
  
  def self.new(base_url, username, userpass)
    @@instance ||= super(base_url)
    unless (@@instance.base_url == base_url)
      @@instance = super(base_url)
    end
    @@instance.authorize(username, userpass)
    @@instance
  end
  
  def initialize(base_url)
    @base_url = base_url
    user_service_namespace = WSDL::Importer.import(base_url + '/services/UserService?wsdl').targetnamespace
    room_service_namespace = WSDL::Importer.import(base_url + '/services/RoomService?wsdl').targetnamespace
    @user = SOAP::RPC::Driver.new(base_url + '/services/UserService', user_service_namespace)  
    @user.add_method('getSession')  
    @user.add_method('loginUser', 'SID', 'username', 'userpass')
    @user.add_method('setUserObjectAndGenerateRoomHashByURL', 'SID', 'username', 'firstname', 'lastname', 'profilePictureUrl', 'email', 'externalUserId', 'externalUserType', 'room_id', 'becomeModeratorAsInt', 'showAudioVideoTestAsInt');
    @user.add_method('getErrorByCode', 'SID', 'errorid', 'language_id')
    @room = SOAP::RPC::Driver.new(base_url + '/services/RoomService', room_service_namespace)  
    @room.add_method('updateRoomWithModeration', 'room_id', 'name', 'roomtypes_id', 'comment', 'numberOfPartizipants', 'ispublic', 'appointment', 'isDemoRoom', 'demoTime', 'isModeratedRoom')
    @room.add_method('getRoomIdByExternalId', 'SID', 'name', 'roomtypes_id', 'comment', 'numberOfPartizipants', 'ispublic', 'appointment', 'isDemoRoom', 'demoTime', 'isModeratedRoom', 'externalRoomId', 'externalRoomType')
    @sid = @user.getSession.session_id
  end
  
  def authorize(username, userpass)
    login_result = @user.loginUser(@sid, username, userpass).to_i
    if login_result < 0
      raise OpenmeetingsError.new(get_remote_error(login_result))
    end
  end
  
  def get_room(external_room_id, name, roomtypes_id, comment, number_of_partizipants, ispublic, is_moderated_room)
    result = @room.getRoomIdByExternalId(@sid, name, roomtypes_id, comment, number_of_partizipants, ispublic, false, false, nil, is_moderated_room, external_room_id, EXTERNAL_TYPE).to_i
    if (result < 0)
      raise OpenmeetingsError.new(get_remote_error(result))
    end
    result
  end
  
  def update_room(room_id, name, roomtypes_id, comment, number_of_partizipants, ispublic, is_moderated_room)
    result = @room.updateRoomWithModeration(@sid, room_id, name, roomtypes_id, comment, number_of_partizipants, ispublic, false, false, nil, is_moderated_room).to_i
    if (result < 0)
      raise OpenmeetingsError.new(get_remote_error(result))
    end
    result
  end
  
  def get_url(username, firstname, lastname, email, user_id, room_id, become_moderator, show_audio_video_test)
    hash = @user.setUserObjectAndGenerateRoomHashByURL(@sid, username, firstname, lastname, nil, email, user_id, EXTERNAL_TYPE, room_id, become_moderator, show_audio_video_test)
    if (hash.length < 32 && hash.to_i < 0) # not a hash, got error
      raise OpenmeetingsError.new(get_remote_error(hash.to_i))
    end
    @base_url + '/?secureHash=' + hash
  end
  
  private
  
  def get_remote_error(error_code)
    @user.getErrorByCode(@sid, error_code, 1) # "1" - english
  end
  
end