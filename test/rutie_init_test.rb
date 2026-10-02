require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'

class RutieInitTest < Minitest::Test
  def setup
    @saved_target_dir = ENV.delete('CARGO_TARGET_DIR')
    @dir = Dir.mktmpdir('rutie')
    @lib_dir = File.join(@dir, 'lib')
    FileUtils.mkdir_p(@lib_dir)
  end

  def teardown
    ENV['CARGO_TARGET_DIR'] = @saved_target_dir if @saved_target_dir
    # Windows can't delete a library that is still loaded, and a loaded
    # library stays loaded, so leave what can't be removed behind.
    FileUtils.rm_rf(@dir)
  end

  def test_missing_library_raises_load_error_naming_the_build_command
    error = assert_raises(Rutie::LibraryNotFound) { Rutie.new(:no_such_ext).init @lib_dir }

    assert_kind_of LoadError, error
    assert_includes error.message, File.join(@dir, 'target', 'release')
    assert_includes error.message, 'cargo build --release'
  end

  def test_debug_build_hint
    error = assert_raises(Rutie::LibraryNotFound) { Rutie.new(:no_such_ext, release: 'debug').init @lib_dir }

    assert_includes error.message, File.join(@dir, 'target', 'debug')
    assert_match(/`cargo build`/, error.message)
  end

  # Builds a C library that stands in for a Rust extension: its init function
  # records that it ran.
  def build_fixture(name, init_name, release_dir)
    cc = RbConfig::CONFIG['CC'].to_s.split.first
    skip 'no C compiler' if cc.nil? || cc.empty? || !system(cc, '--version', out: File::NULL, err: File::NULL)

    rutie = Rutie.new(name)
    FileUtils.mkdir_p(release_dir)
    library = File.join(release_dir, File.basename(rutie.ffi_library(@lib_dir)))
    source = File.join(@dir, "#{name}.c")
    File.write(source, <<~C)
      #ifdef _WIN32
      #define EXPORT __declspec(dllexport)
      #else
      #define EXPORT
      #endif
      static int called = 0;
      EXPORT void #{init_name}(void) { called = 1; }
      EXPORT int fixture_called(void) { return called; }
    C
    flags = RbConfig::CONFIG['host_os'] =~ /darwin/ ? ['-dynamiclib'] : ['-shared', '-fPIC']
    skip 'could not build the fixture library' unless system(cc, *flags, '-o', library, source)

    library
  end

  def fixture_called?(library)
    require 'fiddle'
    function = Fiddle::Function.new(Fiddle.dlopen(library)['fixture_called'], [], Fiddle::TYPE_INT)
    function.call == 1
  end

  def test_init_defaults_to_init_project_name
    library = build_fixture('fixture_ext', 'Init_fixture_ext', File.join(@dir, 'target', 'release'))

    refute fixture_called?(library)
    Rutie.new(:fixture_ext).init @lib_dir
    assert fixture_called?(library)
  end

  def test_init_with_an_explicit_name_and_cargo_target_dir
    target = File.join(@dir, 'shared-target')
    library = build_fixture('fixture_named', 'my_init', File.join(target, 'release'))
    ENV['CARGO_TARGET_DIR'] = target

    Rutie.new(:fixture_named).init 'my_init', @lib_dir
    assert fixture_called?(library)
  end

  def test_missing_init_function_raises_load_error_with_a_hint
    build_fixture('fixture_noinit', 'something_else', File.join(@dir, 'target', 'release'))

    error = assert_raises(Rutie::InitFunctionNotFound) { Rutie.new(:fixture_noinit).init @lib_dir }
    assert_kind_of LoadError, error
    assert_includes error.message, 'Init_fixture_noinit'
    assert_includes error.message, '#[no_mangle]'
  end
end
