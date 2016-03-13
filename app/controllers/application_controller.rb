﻿# encoding: utf-8
require 'json'
require 'digest/md5'
require 'sinatra/decompile'
require 'sinatra/advanced_routes'
require 'sinatra/multi_route'
# require 'rack-livereload'
# require 'rack-mini-profiler'
class ApplicationController < Sinatra::Base
  # use Rack::MiniProfiler
  # Rack::MiniProfiler.config.position = 'right'
  # Rack::MiniProfiler.config.start_hidden = false
  # use Rack::LiveReload, :min_delay => 500

  register Sinatra::Reloader if development? || test?
  register Sinatra::Flash
  register Sinatra::Decompile
  register Sinatra::Logger
  register SinatraMore::MarkupPlugin
  register Sinatra::MultiRoute
  # register Sinatra::AdvancedRoutes
  # register Sinatra::Auth

  # helpers
  helpers ApplicationHelper
  helpers HomeHelper

  # css/js/view配置文档
  use ImageHandler
  use SassHandler
  use JSHandler
  use AssetHandler

  set :root, ENV['APP_ROOT_PATH']
  set :startup_time, Time.now
  set :logger_level, :info # :fatal or :error, :warn, :info, :debug
  enable :sessions, :logging, :static, :method_override

  unless ENV['RACK_ENV'].eql?('production')
    enable :dump_errors, :raise_errors, :show_exceptions
  end

  before do
    set_seo_meta("点滴记录", "SOLife,个人实验室", "segment of jay's life!")
    @request_body = request_body
    begin
      request_hash = JSON.parse(@request_body)
    rescue
      request_hash = {}
    end

    @params = params.merge(request_hash)
    @params = @params.merge(ip: request.ip, browser: request.user_agent)
    @params.deep_symbolize_keys!

    print_format_logger
  end

  # global functions list
  def run_shell(cmd)
    IO.popen(cmd) { |stdout| stdout.reject(&:empty?) }
      .unshift($CHILD_STATUS.exitstatus.zero?)
  end

  # global function
  def uuid(str)
    str += Time.now.to_f.to_s
    md5_key(str)
  end

  def md5_key(str)
    Digest::MD5.hexdigest(str)
  end

  def sample_3_alpha
    (('a'..'z').to_a + ('A'..'Z').to_a).sample(3).join
  end

  def current_user
    @current_user ||= User.first(email: request.cookies['cookie_user_login_state'] || '')
  end

  include Utils::ActionLogger

  # filter
  def authenticate!
    if request.cookies['cookie_user_login_state'].to_s.strip.empty?
      # 记录登陆前的path，登陆成功后返回至此path
      response.set_cookie 'cookie_before_login_path', value: request.url, path: '/', max_age: '2592000'

      flash[:notice] = "继续操作前请登录."
      redirect '/users/login', 302
    end
  end

  def print_format_logger
    log_info = <<-EOF.strip_heredoc
      #{request.request_method} #{request.path} for #{request.ip} at #{Time.now}
      Parameters:
        #{@params}
    EOF
    logger.info log_info
  end

  def request_body(body = request.body)
    case body
    when StringIO then body.string
    when Tempfile,
      # gem#passenger is ugly!
      #     it will change the structure of REQUEST
      #     detail at: https://github.com/phusion/passenger/blob/master/lib/phusion_passenger/utils/tee_input.rb
      (defined?(PhusionPassenger) && PhusionPassenger::Utils::TeeInput),
      # gem#unicorn
      #     it also change the strtucture of REQUEST
      (defined?(Unicorn) and Unicorn::TeeInput),
      (defined?(Rack) and Rack::Lint::InputWrapper)

      body.read if body.respond_to?(:read)
    else
      body.to_str
    end.to_s.strip
  rescue => e
    e.message
  end

  def respond_with_json(hash = {}, code = nil)
    code ||= 200
    hash[:code] ||= code
    content_type 'application/json;charset=utf-8'

    body   hash.to_json
    status code
  end

  def set_seo_meta(title = '', meta_keywords = '', meta_description = '')
    @page_title       = title
    @meta_keywords    = meta_keywords
    @meta_description = meta_description
  end

  def app_root_join(path)
    File.join(settings.root, path)
  end

  def cache_with_custom_defined(filepath)
    if File.exist?(filepath) && ENV['RACK_ENV'].eql?('production')
      mtime = File.mtime(filepath)
      mtime = settings.startup_time > mtime ? settings.startup_time : mtime

      last_modified mtime
      etag md5_key(mtime.to_s)
    end
  end

  def human_filesize(filepath)
    filesize = File.size?(filepath)
    filesize ||= 0

    human_units = %w(K M G T P)
    human_sizes = []
    puts filesize
    while filesize > 1024
      filesize /= 1024
      human_sizes.push(filesize % 1024)
      puts filesize
    end

    human_group = []
    puts human_sizes
    human_sizes.each_with_index do |size, index|
      human_group.push('%s%s' % [size, human_units[index]])
    end

    human_group.reverse.join
  end

  # 404 page
  not_found do
    haml :"shared/not_found", views: ENV['VIEW_PATH'] # , layout: :"layouts/layout"
  end
end
