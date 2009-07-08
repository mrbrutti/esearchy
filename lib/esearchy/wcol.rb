require 'Win32API'
class Wcol
  gsh = Win32API.new("kernel32", "GetStdHandle", ['L'], 'L') 
  @textAttr = Win32API.new("kernel32","SetConsoleTextAttribute", ['L','N'], 'I')
  @h = gsh.call(-11)
  
  def self.color(col)
    @textAttr.call(@h,col)
  end
end
