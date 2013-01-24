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
class ConferenceController < ApplicationController
  before_filter :find_project
  before_filter :authorize
  
  def settings
  end

  def index
    base_url = Setting.plugin_openmeetings['url']
    login = Setting.plugin_openmeetings['login']
    password = Setting.plugin_openmeetings['password']
    unless (User.current.class == AnonymousUser)
      puts "get session"
      session = OpenmeetingsSession.new(base_url, login, password)
      puts "get room_id"
      room_id = session.get_room(@project.id, @project.name, 1, @project.description, nil, false, true)
      puts room_id
      moderator = User.current.allowed_to?(:moderate_conference, @project) ? 1 : 0
      puts "get link"
      p User.current
      @link = session.get_url(User.current.login, User.current.firstname, User.current.lastname, User.current.mail, User.current.login, room_id, moderator, 0);
    else
      @link = base_url
    end
  rescue OpenmeetingsSession::OpenmeetingsError => e
    @error_message = l(:om_error) + ": " + e.message
  rescue Errno::ECONNREFUSED => e
    @error_message = l(:error_connection_refused)
  rescue HTTPClient::ConnectTimeoutError => e
    @error_message = l(:error_connection_timeout)
  end
  
  private
  
  def find_project
    # @project variable must be set before calling the authorize filter
    if params[:project_id]
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  # Authorize the user for the requested action
  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project, :global => global)
    allowed ? true : deny_access
  end
end
