require "pathname"
require "set"

class CompactIndexClient
  require "compact_index_client/cache"
  require "compact_index_client/updater"
  require "compact_index_client/version"

  attr_reader :directory

  def initialize(directory, fetcher)
    @directory = Pathname.new(directory)
    @updater = Updater.new(fetcher)
    @cache = Cache.new(@directory)
    @endpoints = Set.new
    @info_checksums_by_name = {}
  end

  def names
    update(@cache.names_path, "names")
    @cache.names
  end

  def versions
    update(@cache.versions_path, "versions")
    versions, @info_checksums_by_name = @cache.versions
    versions
  end

  def dependencies(names)
    names.each {|n| update_info(n) }
    names.map do |name|
      @cache.dependencies(name).map {|d| d.unshift(name) }
    end.flatten(1)
  end

  def spec(name, version, platform = nil)
    update_info(name)
    @cache.specific_dependency(name, version, platform)
  end

private

  def update(local_path, remote_path)
    return if @endpoints.include?(remote_path)
    @updater.update(local_path, url(remote_path))
    @endpoints << remote_path
  end

  def update_info(name)
    path = @cache.dependencies_path(name)
    return if @info_checksums_by_name[name] == @updater.checksum_for_file(path)
    update(path, "info/#{name}")
  end

  def url(path)
    path
  end
end
