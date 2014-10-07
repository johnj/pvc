#!/usr/bin/env ruby
# derived from https://github.com/reidmorrison/hyperic-passenger/blob/master/passenger-plugin.xml, modified for pvc

require 'optparse'
require 'rexml/document'
include REXML
require 'open3'
include Open3

options = { :rack_app_path => ARGV.count > 0 ? ARGV[0] : ''}

if options[:rack_app_path].empty?
  puts "Missing required command line arguments: #{$0} puppet_rack_app_path"
  exit
end

begin
  xml, stderr, status = Open3.capture3(ENV,"passenger-status --show=xml")
rescue Errno::ENOENT
  puts 'Could not run passenger-status.'
rescue  Exception => e
  puts e.message
  puts e.backtrace.inspect
end
passenger_status = {}
passenger_status[:passenger_active] = 0

# borrowing try from ActiveSupport
class Object
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end
end
class NilClass
  def try(*args)
    nil
  end
end

if xml =~ /<?xml/
  passenger_status[:passenger_active] = 1
  rx = Document.new(xml)
  passenger_status[:global_process_count] = XPath.first(rx, '//info/process_count').text || ''
  passenger_status[:global_get_wait_list_size] = XPath.first(rx, '//info/get_wait_list_size').text || ''
  passenger_status[:'application_active_processes'] = XPath.first(rx, "sum(//process[command = 'Passenger RackApp: #{options[:rack_app_path]}']/sessions)").try(:to_i) || ''
  passenger_status[:'application_enabled_process_count'] = XPath.first(rx, "//group[app_root = '#{options[:rack_app_path]}']/enabled_process_count").try(:text) || ''
  passenger_status[:'application_get_wait_list_size'] = XPath.first(rx, "//group[app_root = '#{options[:rack_app_path]}']/get_wait_list_size").try(:text) || ''
  passenger_status[:'application_processed'] = XPath.first(rx, "sum(//process[command = 'Passenger RackApp: #{options[:rack_app_path]}']/processed)").try(:to_i) || ''
  passenger_status[:'application_real_memory'] = XPath.first(rx, "sum(//process[command = 'Passenger RackApp: #{options[:rack_app_path]}']/real_memory)") || ''
  passenger_status[:'application_vmsize'] = XPath.first(rx, "sum(//process[command = 'Passenger RackApp: #{options[:rack_app_path]}']/vmsize)") || ''
  passenger_status[:'system_load5'] = Open3.capture3(ENV, "cat /proc/loadavg | awk '{ print $1 }'")[0].try(:to_f) || ''
end
passenger_status.sort.each {|key,val| puts "#{key}=#{val}"}
