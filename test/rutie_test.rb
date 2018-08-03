require 'test_helper'

class RutieTest < Minitest::Test
  def test_it_works
    library = Rutie.new('example').ffi_library

    assert_includes library, 'target'
    assert_includes library, 'release'
    assert_includes library, 'example'
  end

  def test_linux_path_works
    library = Rutie.new('example', os: 'linux').ffi_library

    assert_includes library, 'libexample.so'
  end

  def test_mac_path_works
    library = Rutie.new('example', os: 'darwin').ffi_library

    assert_includes library, 'libexample.dylib'
  end

  def test_windows_path_works
    library = Rutie.new('example', os: 'windows').ffi_library

    assert_includes library, 'example.dll'
  end

  def test_cygwin_path_works
    library = Rutie.new('example', os: 'cygwin').ffi_library

    assert_includes library, 'cygexample.dll'
  end
end
