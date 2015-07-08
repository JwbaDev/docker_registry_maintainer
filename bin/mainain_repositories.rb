#!/usr/bin/env ruby

require 'rubygems'
require 'docker_registry'
require 'optparse'
require 'uri'
require 'logger'
require 'json'
require 'base64'
require 'pp'

OPTIONS = {
  :user => ENV["DOCKER_USER"],
  :pass => ENV["DOCKER_PASS"],
  :host => ENV["DOCKER_HOST"],
  :namespace => ENV["DOCKER_NAMESPACE"],
  :keep => Integer(ENV.fetch("DOCKER_KEEP", 10)),
  :sort => false,
  :ssl => true,
  :kill => false
}

LOGGER = Logger.new(STDOUT)

# @return [Array<String, String>] the url and a url with obfuscated password
def repo_url
  OPTIONS[:ssl] ? builder = URI::HTTPS : builder = URI::HTTP

  uri = builder.build(
    :host => OPTIONS[:host],
  )

  uri.user = OPTIONS[:user]
  uri.password = URI.escape(OPTIONS[:pass])

  url = uri.to_s

  uri.password = "*" * uri.password.size

  [url, uri.to_s]
end

def check_options!
  needed = OPTIONS.map do |k, v|
    v.nil? ? k : nil
  end.compact

  abort("Please specify a value for settings: %s. Run with --help for details" % needed.join(", ")) unless needed.empty?

  OPTIONS[:url], OPTIONS[:clean_url] = repo_url
end

def registry
  @registry ||= DockerRegistry::Registry.new(OPTIONS[:url])
end

def get_repos
  repos = registry.search(OPTIONS[:namespace])

  abort("Could not find any repositories at %s" % OPTIONS[:clean_url]) if repos.empty?

  repos
end

def manage_repos!
  repos = get_repos

  LOGGER.info("Managing tags in %d repositories from %s/%s" % [repos.size, OPTIONS[:clean_url], OPTIONS[:namespace]])

  repos.each do |repository|
    if OPTIONS[:sort]
      LOGGER.warn("Sorting repositories based on name")
      tags = repository.tags.sort_by{|t| t.name}
    else
      tags = repository.tags
    end

    if tags.size > OPTIONS[:keep]
      delete_count = tags.size - OPTIONS[:keep]
      delete_targets = tags[0...delete_count]

      LOGGER.debug("Repository %s has %d tags removing %d" % [repository.name, tags.size, delete_count])
      LOGGER.debug("Repositor tags: %s" % [tags.map{|t| t.name}.join(", ")])
      LOGGER.debug("Tags being deleted: %s" % [delete_targets.map{|t| t.name}.join(", ")])

      delete_targets.each do |tag|
        if tag.name != "latest"
          if OPTIONS[:kill]
            LOGGER.info("Removing %s:%s" % [repository.name, tag.name])
            registry.delete_reporitory_tag(tag)
          else
            LOGGER.info("Would have removed %s:%s" % [repository.name, tag.name])
          end
        else
          LOGGER.debug("Not removing latest tag")
        end
      end
    else
      LOGGER.debug("Repository %s has %d tags" % [repository.name, tags.size])
    end
  end
end

def parse_docker_config
  if File.exist?(path = File.expand_path("~/.dockercfg"))
    config = JSON.parse(File.read(path))

    if host = config[OPTIONS[:host]]
      LOGGER.debug("Found base64 encoded credentials in %s" % path)
      OPTIONS[:user], OPTIONS[:pass] = Base64.decode64(host["auth"]).split(":")
    end
  end
end

def parse_options
  opt = OptionParser.new
  opt.on("--user [USER]", "-u", "User name") do |v|
    OPTIONS[:user] = v
  end

  opt.on("--pass [PASS]", "-p", "User password") do |v|
    OPTIONS[:pass] = v
  end

  opt.on("--host [HOST]", "-r", "Repository Host") do |v|
    OPTIONS[:host] = v
  end

  opt.on("--namespace [NAMESPACE]", "-n", "Repository namespace") do |v|
    OPTIONS[:namespace] = v
  end

  opt.on("--keep [KEEP]", "-n", "Tags to keep") do |v|
    OPTIONS[:keep] = Integer(v)
  end

  opt.on("--ssl", "Use SSL") do
    OPTIONS[:ssl] = true
  end

  opt.on("--phasers-to-kill", "Enable deletion of tags") do
    OPTIONS[:kill] = true
  end

  opt.on("--sort", "Sort the tags by tag name") do |v|
    OPTIONS[:sort] = v
  end

  opt.parse!
end

parse_options

if !(OPTIONS[:user] && OPTIONS[:pass])
  parse_docker_config
end

check_options!

manage_repos!
