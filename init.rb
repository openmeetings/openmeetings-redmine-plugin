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
require 'openmeetings_session.rb'

Redmine::Plugin.register :openmeetings do
  name 'Openmeetings plugin'
  author 'Artyom Horuzhenko'
  description 'This plugin allows using Apache Openmeetings in Redmine'
  version '0.1.0'
  #url 'http://example.com/path/to/plugin'
  requires_redmine :version_or_higher => '2.0.0'
  settings :default => {'url' => 'http://demo.dataved.ru:5080/openmeetings', 'login' => 'redmine', 'password' => 'redmine__password'}, :partial => 'conference/settings'
  
  project_module :conference do
    permission :enter_conference, :conference => :index
    permission :moderate_conference, {}
  end
  
  menu :project_menu, :conference, { :controller => 'conference', :action => 'index' }, :param => :project_id, :caption => :conference, :if => Proc.new { |p| User.current.allowed_to?(:enter_conference, p) }
  
end
