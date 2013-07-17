module ActiveRecord::Metal::Postgresql::Conversions
  module Numeric; end
  module Time; end
  module Date; end
  module Boolean; end
  module String; end
  module HStore; end

  include Numeric, Time, Date, Boolean, String, HStore
  extend self
  
  def resolve_type(symbol)
    sub_converter = included_modules.detect { |mod| mod.method_defined?(symbol) }
    sub_converter ? sub_converter::T : String
  end
end

module ActiveRecord::Metal::Postgresql::Conversions::Numeric
  T = ::Numeric
  
  def _numeric(s)
    s =~ /\D/ ? Float(s) : Integer(s)
  end

  def _int(s)
    Integer(s)
  end

  def _float(s);    
    Float(s)
  rescue ArgumentError
    case s
    when /^Infinity$/   then Float::INFINITY
    when /^-Infinity$/  then -Float::INFINITY
    when /^NaN$/        then Float::NAN
    else raise
    end
  end

  def _money(s)
    Float s.gsub(/[^-0-9.]/, "")
  end
  
  def _oid(s)
    Integer(s)
  end
end

module ActiveRecord::Metal::Postgresql::Conversions::Date
  T = ::Date
  
  def _date(s)
    T.parse(s)
  end
end

module ActiveRecord::Metal::Postgresql::Conversions::Time
  T = ::Time

  def _time(s)
    T.parse(s)
  end
  
  def _timestamp(s)
    T.parse(s)
  end
  
  def _timetz(s)
    T.parse(s)
  end
  
  def _timestamptz(s)
    T.parse(s)
  end
end

module ActiveRecord::Metal::Postgresql::Conversions::Boolean
  T = ::TrueClass
  
  def _bool(s);         s == "t"; end
end

module ActiveRecord::Metal::Postgresql::Conversions::String
  T = ::String
  
  def _varchar(s)
    s
  end
  
  def _text(s)
    s
  end
  
  def _default(s)
    s
  end
  
  def _name(s)
    s
  end

  def _enum(s)
    s
  end
end

module ActiveRecord::Metal::Postgresql::Conversions::HStore
  SELF = self
  
  T = ::Hash
  NULL = nil
  
  def _hstore(s)
    SELF.unescape(s)
  end
  
  HSTORE_ESCAPED = /[,\s=>\\]/

  # From activerecord-postgres-hstore, r0.6
  # Escapes values such that they will work in an hstore string
  def self.escape_string(str)
    if str.nil?
      return 'NULL'
    end

    str = str.to_s
    # backslash is an escape character for strings, and an escape character for gsub, so you need 6 backslashes to get 2 in the output.
    # see http://stackoverflow.com/questions/1542214/weird-backslash-substitution-in-ruby for the gory details
    str = str.gsub(/\\/, '\\\\\\')
    # escape backslashes before injecting more backslashes
    str = str.gsub(/"/, '\"')

    if str =~ HSTORE_ESCAPED or str.empty?
      str = '"%s"' % str
    end

    return str
  end

  def self.escape(hsh, connection=ActiveRecord::Base.connection)
    hsh.map do |idx, val| 
      "%s=>%s" % [escape_string(idx), escape_string(val)]
    end * ","
  end
  
  # Creates a hash from a valid double quoted hstore format, 'cause this is the format
  # that postgresql spits out.
  def self.unescape(str)
    token_pairs = (str.scan(hstore_pair)).map { |k,v| [k,v =~ /^NULL$/i ? nil : v] }
    token_pairs = token_pairs.map { |k,v|
      [ unescape_string(k).to_sym, unescape_string(v) ]
    }
    ::Hash[ token_pairs ]
  end

  def self.unescape_string(str)
    case str
    when nil then str
    when /\A"(.*)"\Z/m then $1.gsub(/\\(.)/, '\1')
    else str.gsub(/\\(.)/, '\1')
    end
  end

  def self.hstore_pair
    quoted_string = /"[^"\\]*(?:\\.[^"\\]*)*"/
    unquoted_string = /[^\s=,][^\s=,\\]*(?:\\.[^\s=,\\]*|=[^,>])*/
    string = /(#{quoted_string}|#{unquoted_string})/
    /#{string}\s*=>\s*#{string}/
  end
end
