class Rutie
  def initialize(project_name, **opts)
    @os = opts.fetch(:os) { nil } # for testing purposes

    @project_name = ProjectName.new(project_name)
    @lib_prefix = opts.fetch(:lib_prefix) { set_prefix }
    @lib_suffix = opts.fetch(:lib_suffix) { set_suffix }
    @release = opts.fetch(:release) { 'release' }
    @full_lib_path = opts.fetch(:lib_path) { nil }
  end

  def ffi_library(dir)
    file = [ @lib_prefix, @project_name, '.', @lib_suffix ]

    File.join(lib_path(dir), file.join())
  end

  def init(c_init_method_name, dir)
    require 'fiddle'

    Fiddle::Function.new(Fiddle.dlopen(ffi_library dir)[c_init_method_name], [], Fiddle::TYPE_VOIDP).call
  end

  private
  def lib_path(dir)
    path = @full_lib_path || "../target/#{@release}"

    File.expand_path(path, dir)
  end

  def set_prefix
    case operating_system()
    when /windows/ then ''
    when /cygwin/ then 'cyg'
    else 'lib'
    end
  end

  def set_suffix
    case operating_system()
    when /darwin/ then 'dylib'
    when /windows|cygwin/ then 'dll'
    else 'so'
    end
  end

  def host_os
    @os || RbConfig::CONFIG['host_os'].downcase
  end

  def operating_system
    case host_os()
    when /linux|bsd|solaris/ then 'linux'
    when /darwin/ then 'darwin'
    when /mingw|mswin/ then 'windows'
    else host_os()
    end
  end

  class ProjectName
    def initialize(name)
      @name = "#{name}"
      raise InvalidProjectName unless valid_name?(@name)
    end

    def to_str
      @name
    end

    private
    def valid_name?(project)
      project.chars.all? {|c| c[/[a-z_]/] }
    end

    class InvalidProjectName < StandardError
      def message
        "Invalid project name.  Please use snake_case naming."
      end
    end
  end
  private_constant :ProjectName
end
