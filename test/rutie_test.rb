require 'test_helper'

class RutieTest < Minitest::Test
  def setup
    @saved_target_dir = ENV.delete('CARGO_TARGET_DIR')
  end

  def teardown
    ENV['CARGO_TARGET_DIR'] = @saved_target_dir if @saved_target_dir
  end

  def test_it_works
    library = Rutie.new('example').ffi_library __dir__

    assert_includes library, 'target'
    assert_includes library, 'release'
    assert_includes library, 'example'
  end

  def test_linux_path_works
    library = Rutie.new('example', os: 'linux').ffi_library __dir__

    assert_includes library, 'libexample.so'
  end

  def test_mac_path_works
    library = Rutie.new('example', os: 'darwin').ffi_library __dir__

    assert_includes library, 'libexample.dylib'
  end

  def test_windows_path_works
    library = Rutie.new('example', os: 'windows').ffi_library __dir__

    assert_includes library, 'example.dll'
  end

  def test_cygwin_path_works
    library = Rutie.new('example', os: 'cygwin').ffi_library __dir__

    assert_includes library, 'cygexample.dll'
  end

  def test_lib_path_option
    library = Rutie.new('example', os: 'linux', lib_path: '../build').ffi_library __dir__

    assert_equal File.expand_path('../build/libexample.so', __dir__), library
  end

  def test_cargo_target_dir_is_used_when_set
    ENV['CARGO_TARGET_DIR'] = '/tmp/rutie-shared-target'
    library = Rutie.new('example', os: 'linux').ffi_library __dir__

    assert_equal File.expand_path('/tmp/rutie-shared-target/release/libexample.so'), library
  end

  def test_project_names_may_contain_digits
    library = Rutie.new(:ext2, os: 'linux').ffi_library __dir__

    assert_includes library, 'libext2.so'
  end

  def test_invalid_project_names_are_rejected
    %w[Example my-ext 2ext].each do |name|
      assert_raises(StandardError) { Rutie.new(name) }
    end
  end
end
