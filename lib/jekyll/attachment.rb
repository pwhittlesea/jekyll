# frozen_string_literal: true

module Jekyll
  module Drops
    class AttachmentDrop < Drop
      delegate_methods :basename, :extname, :name, :url
      delegate_method_as :relative_path, :path
      private delegate_method_as :data, :fallback_data
    end
  end

  class Attachment
    extend Forwardable

    attr_reader :doc, :data, :name, :basename, :extname, :relative_path, :path
    alias_method :basename_without_ext, :name

    def_delegators :doc, :date, :site, :collection

    def initialize(doc, dir, name)
      @doc = doc
      @data = {
        "categories" => doc.data["categories"],
      }
      @name = name
      @basename = File.basename(name, ".*")
      @extname = File.extname(name)
      @relative_path = PathManager.join(dir, name)
      @path = site.in_source_dir(@relative_path)
    end

    def to_liquid
      @to_liquid ||= Drops::AttachmentDrop.new(self)
    end

    def url
      @url ||= begin
        base_url = @doc.url
        if base_url.end_with?("/")
          File.join(base_url, name)
        else
          # Remove the last part of the post URL
          File.join(File.dirname(@doc.url), name)
        end
      end
    end

    def write(dest)
      # dest should be the directory the associated document is written to already
      dest_path = File.join(dest, name)
      if File.exist?(dest_path)
        raise IOError, "Attachment '#{relative_path}' has the same path as an attachment from another post"
      else
        FileUtils.mkdir_p(File.dirname(dest_path))
      end

      Jekyll.logger.info "Writing:", dest_path
      FileUtils.cp(path, dest_path)
    end

    def inspect
      "#<#{self.class} #{name.inspect} for #{@doc.relative_path.inspect}>"
    end
    alias_method :to_s, :inspect
  end
end
