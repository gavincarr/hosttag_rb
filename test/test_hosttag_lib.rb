#!/usr/bin/ruby

require 'test/unit'
require 'fileutils'

require 'hosttag'
include Hosttag

class TestHosttagLib < Test::Unit::TestCase
  def setup
    @test_args = '--server localhost --ns hosttag_testing'
    @test_opts = { :server => 'localhost', :namespace => 'hosttag_testing',
      :delete => true, :autoconfirm => true, :debug => false }
    datadir = "#{File.dirname(__FILE__)}/data_hosttag"
    bindir = File.join(File.dirname(__FILE__), '..', 'bin')
    File.directory?(datadir) or throw "missing datadir #{datadir}"
    hosttag_import_from_directory(datadir, @test_opts)
  end

  # format: args (array), options (hash) => expected (array)
  TAGSET = [
    [ %w{centos},           {},                 %w{a m n} ],
    [ %w{laptop},           {},                 %w{n} ],
    [ %w{vps},              {},                 %w{m} ],
    [ %w{laptop vps},       {},                 %w{} ],
    [ %w{laptop vps},       { :rel => :and },   %w{} ],
    [ %w{laptop vps},       { :rel => :or },    %w{m n} ],
    # namespace tests
    [ %w{public namespace2::prod::engine},       { :rel => :or },    %w{a m} ],
    [ %w{namespace2::},     {},                 %w{a m n} ],
    [ %w{namespace2::dc1},  {},                 %w{a m n} ],
    [ %w{rack1::},          {},                 %w{m} ],
  ]
  HOSTSET = [
    [ %w{n},                {},                 %w{centos centos5 centos5-i386 laptop namespace2::dc1::rack2} ],
    [ %w{a},                {},                 %w{centos centos5 centos5-x86_64 namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public} ],
    [ %w{m},                {},                 %w{centos centos4 centos4-x86_64 namespace2::dc1::rack1 namespace2::prod::engine public vps} ],
    [ %w{a n},              {},                 %w{centos centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public} ],
    [ %w{a n},              { :rel => :or },    %w{centos centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack2 namespace2::staging::engine public} ],
    [ %w{a n},              { :rel => :and },   %w{centos centos5 namespace2::dc1::rack2} ],
    [ %w{a n m},            { :rel => :and },   %w{centos} ],
    # namespace tests 
    [ %w{a_meta},           {},                 %w{dc1:: dc1::rack2 engine:: namespace1:: namespace2:: namespace2::dc1 namespace2::staging rack2:: staging:: staging::engine test::} ],
    
  ]

  def test_hosttag_lookup
    TAGSET.each do |args, opts, expected|
      opts.merge!(@test_opts)
      got = hosttag_lookup(args, opts)
      assert_equal(expected, got, "args: #{args}")
    end
    HOSTSET.each do |args, opts, expected|
      opts.merge!(@test_opts)
      got = hosttag_lookup(args, opts)
      assert_equal(expected, got, "args: #{args}")
    end
  end

  def test_hosttag_lookup_tags
    TAGSET.each do |args, opts, expected|
      opts.merge!(@test_opts)
      got = hosttag_lookup_tags(args, opts)
      assert_equal(expected, got, "args: #{args}")
    end
  end

  def test_hosttag_lookup_hosts
    HOSTSET.each do |args, opts, expected|
      opts.merge!(@test_opts)
      got = hosttag_lookup_hosts(args, opts)
      assert_equal(expected, got, "args: #{args}")
    end
  end

  # format: options (hash) => expected (array)
  TAGSET_ALL = [
    [ {},                           %w{centos centos4 centos4-x86_64 centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack1 namespace2::dc1::rack2 namespace2::prod::engine namespace2::staging::engine public vps} ],
    [ { :include_skip? => true },   %w{SKIP centos centos4 centos4-i386 centos4-x86_64 centos5 centos5-i386 centos5-x86_64 laptop namespace1::test namespace2::dc1::rack1 namespace2::dc1::rack2 namespace2::prod::engine namespace2::staging::engine public vps} ],
  ]
  def test_hosttag_all_tags
    TAGSET_ALL.each do |opts, expected|
      mopts = opts.merge(@test_opts)
      got = hosttag_all_tags(mopts)
      assert_equal(expected, got, "opts: #{opts}")
    end
  end

  # format: options (hash) => expected (array)
  HOSTSET_ALL = [
    [ {},                           %w{a m n} ],
    [ { :include_skip? => true },   %w{a g h m n} ],
  ]
  def test_hosttag_all_hosts
    HOSTSET_ALL.each do |opts, expected|
      mopts = opts.merge(@test_opts)
      got = hosttag_all_hosts(mopts)
      assert_equal(expected, got, "opts: #{opts}")
    end
  end

    # Invalid data
  INVALID_TAGS = [
    [ %w{foo},                  %r{ \btag\b  .* not\sfound }x ],
    [ %w{centos foo},           %r{ \btag\b  .* not\sfound }x ],
  ]
  INVALID_HOSTS = [
    [ %w{foo},                  %r{ \bhost\b .* not\sfound }x ],
    [ %w{n foo},                %r{ \bhost\b .* not\sfound }x ],
  ]

  def test_invalid_data
    INVALID_TAGS.each do |args, expected|
      exception = assert_raise RuntimeError do
        hosttag_lookup_tags(args)
      end
      assert_match expected, exception.message, "args: #{args}"
    end
    INVALID_HOSTS.each do |args, expected|
      exception = assert_raise RuntimeError do
        hosttag_lookup_hosts(args)
      end
      assert_match expected, exception.message, "args: #{args}"
    end
  end
end

