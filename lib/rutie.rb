class Rutie
  # Raised by #init when the compiled Rust library is not where Rutie looks for
  # it. A LoadError, so code that rescues LoadError keeps working.
  class LibraryNotFound < LoadError; end

  # Raised by #init when the library has no function with the init name.
  class InitFunctionNotFound < LoadError; end

  def initialize(project_name, **opts)
    @os = opts.fetch(:os) { nil } # for testing purposes

    @project_name = ProjectName.new(project_name)
    @lib_prefix = opts.fetch(:lib_prefix) { set_prefix }
    @lib_suffix = opts.fetch(:lib_suffix) { set_suffix }
    @release = opts.fetch(:release) { 'release' }
    @full_lib_path = opts.fetch(:lib_path) { nil }
  end

  # The path of the compiled library. With no `lib_path` option, Rutie looks in
  # `$CARGO_TARGET_DIR/<release>` when that variable is set, then in
  # `../target/<release>` relative to `dir`, and returns the first that holds
  # the library (or the first candidate when none does).
  def ffi_library(dir)
    candidates = library_candidates(dir)

    candidates.find { |path| File.exist?(path) } || candidates.first
  end

  # Loads the compiled Rust library and calls its init function, which defaults
  # to `Init_<project_name>`:
  #
  #   Rutie.new(:my_ext).init __dir__
  #   Rutie.new(:my_ext).init 'Init_my_ext', __dir__
  def init(c_init_method_name = "Init_#{@project_name}", dir)
    library = ffi_library(dir)
    raise LibraryNotFound, library_not_found_message(dir) unless File.exist?(library)

    require 'fiddle'

    handle = Fiddle.dlopen(library)
    function =
      begin
        handle[c_init_method_name]
      rescue Fiddle::DLError
        raise InitFunctionNotFound, init_not_found_message(library, c_init_method_name)
      end

    Fiddle::Function.new(function, [], Fiddle::TYPE_VOIDP).call
  end

  private
  def library_file
    [ @lib_prefix, @project_name, '.', @lib_suffix ].join
  end

  def library_candidates(dir)
    file = library_file

    return [File.join(File.expand_path(@full_lib_path, dir), file)] if @full_lib_path

    candidates = []
    target_dir = ENV['CARGO_TARGET_DIR']
    # Cargo resolves a relative CARGO_TARGET_DIR against the working directory.
    candidates << File.join(File.expand_path(@release, target_dir), file) unless target_dir.nil? || target_dir.empty?
    candidates << File.join(File.expand_path("../target/#{@release}", dir), file)
    candidates.uniq
  end

  def library_not_found_message(dir)
    profile = @release == 'release' ? ' --release' : ''

    "Rutie could not find the compiled library for #{@project_name}. " \
      "Looked for: #{library_candidates(dir).join(', ')}. " \
      "Build it with `cargo build#{profile}` (see Rutie::RakeTask), " \
      "or pass `lib_path:` to Rutie.new."
  end

  def init_not_found_message(library, name)
    "#{library} has no function #{name}. Define it in Rust as " \
      "`#[no_mangle] pub extern \"C\" fn #{name}()`, or pass its name to Rutie#init."
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
    alias to_s to_str

    private
    # A Cargo library name: snake_case, and digits after the first character.
    def valid_name?(project)
      project.match?(/\A[a-z_][a-z0-9_]*\z/)
    end

    class InvalidProjectName < StandardError
      def message
        "Invalid project name.  Please use snake_case naming."
      end
    end
  end
  private_constant :ProjectName
end
