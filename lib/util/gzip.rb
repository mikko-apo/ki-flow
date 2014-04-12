require 'zlib'
require 'stringio'
require 'json'

module Ki
  class Gzip
    def self.gunzip(data)
      io = StringIO.new(data, "rb")
      gz = Zlib::GzipReader.new(io)
      decompressed = gz.read
    end

    def self.gzip(string)
      wio = StringIO.new("w")
      w_gz = Zlib::GzipWriter.new(wio)
      w_gz.write(string)
      w_gz.close
      compressed = wio.string
    end
  end
end
