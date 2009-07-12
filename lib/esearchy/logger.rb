class Logger
  
  def initialize(level, output)
    @level = level
    if output.class == IO
      @device = output
    else
      @device = File.new(output, "a")
    end
    @device.sync = true
  end
  attr_accessor :level, :device
  
  def puts(msg)
    if @level > 1
      begin
        @device.puts clean(msg) + "\n"
      rescue
        Raise "Something went Wrong writing to [file|IO]"
      end
    end
  end
  
  def clean(msg)
    msg.match(/\n|\r/) != nil ? msg.strip!  : msg
  end
  
  def close
   @device.close if @open
  end
end