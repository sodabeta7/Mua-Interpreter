class Reader
  attr_reader :user_f
  def initialize(f)
    @fname=f
    @user_f={}
  end  
  def read_list
    @ws=[]    
    File.open(@fname).each do |w|      
      w.strip.split(/(\s+|\[|\])/).each{|ww| @ws<<ww if not ww.strip.empty?}
    end    
    @k=0
    parse_func()
    @list=[]
    while @k<@ws.size
      @list<<parse();@k+=1
      while @k<@ws.size and (@ws[@k]==']' or @ws[@k]=='[')
        @k+=1
      end
      break if @k >= @ws.size            
    end
    @list
  end
  def parse_func()
    k=0
    while k<@ws.size
      curw=@ws[k]      
      if curw == "make"
        k+=1;s=@ws[k]
        user_f_name=(s[0]=='"' or s[0]==':') ? s[1..-1].to_sym : s.to_sym        
        if @ws[k+=1]=='['          
          while @ws[k]=='['
            k+=1
          end
          c=0
          while k<@ws.size and @ws[k]!=']'
            c+=1;k+=1
          end
          @user_f[user_f_name]=c          
        end
      else
        k+=1
      end        
    end
  end
  def parse()
    return nil if @k>=@ws.size or @ws[@k]==']'
    curw=@ws[@k]
    @k+=1 if curw == '['
    curw=@ws[@k]
    p=[]
    if curw == "make"
      p<<:make;@k+=1;p<<(user_f_name=parse_word())      
      q=[]
      if @ws[@k+=1]=='['
        qq=[]
        while @ws[@k]=='['
          @k+=1
        end
        while @k<@ws.size and @ws[@k]!=']'
          qq<<parse_word().to_sym;@k+=1          
        end          
        q<<qq
        @k+=1
        qq=[]
        while @k<@ws.size and @ws[@k]!=']'
          qq<<parse()
          @k+=1
        end
        q<<qq;p<<q        
      else
        p<<parse()
      end 
      return p
    else      
      case curw
      when 'thing','erase','isname','random','sqrt'
        p << @ws[@k].to_sym << @ws[@k+=1].to_sym
      when 'print','isnumber','isword','islist','isbool','test','output'        
        p << @ws[@k].to_sym; @k+=1; p << (parse());        
      when 'read','readlinst','stop','erall','poall'
        p << @ws[@k].to_sym    
        return p
      when 'add','sub','mul','div','mod','eq','gt','lt','and','or'
        p << @ws[@k].to_sym; @k+=1; p << parse(); @k+=1; p << parse();      
      when 'not'
        p << @ws[@k].to_sym; p << parse_bool(@ws[@k+=1])
      when 'iftrue','iffalse'
        p << @ws[@k].to_sym; @k+=1; p << parse_list()
      when 'list'
        p << @ws[@k].to_sym; @k+=1; p << parse_value(); @k+=1; p << parse_value()
      when 'join'
        p << @ws[@k].to_sym; @k+=1; p << parse_list(); @k+=1; p << parse_sts_list()
      when 'first','last','butfirst','butlast','isempty'
        p << @ws[@k].to_sym; @k+=1; p << parse_value()
      when 'item'
        p << @ws[@k].to_sym; p << @ws[@k+=1].to_i; @k+=1; p << parse_word_list()
      when 'repeat'
        p << @ws[@k].to_sym; p << @ws[@k+=1].to_i; @k+=1; p << parse_list()
      when 'wait'
        p << @ws[@k].to_sym; p << @ws[@k+=1].to_i
      when 'save','load'
        p << @ws[@k].to_sym; @k+=1; p << parse_word()
      when is_func(curw)        
        p<<@ws[@k].to_sym; q=[];@k+=1;
        @user_f[curw.to_sym].downto(1){|k| q<<parse_sts_list();@k+=1 if k>1}
        p<<q      
      else
        return parse_item(@ws[@k])
      end      
      return p
    end
  end  
  def is_func(s)
    lambda {|r| @user_f.has_key? s.to_sym}    
  end
  def parse_list()
    p = []
    while @k<@ws.size and @ws[@k+=1] != ']'
      p << parse()
    end
    return p
  end
  def parse_value()
    curw = @ws[@k]
    if curw == '['
      return parse_list
    elsif curw[0]==':'
      return parse_word
    else
      return parse      
    end
  end
  def parse_word()    
    s=@ws[@k]
    return (s[0]=='"' or s[0]==':') ? s[1..-1].to_sym : s.to_sym
  end
  def parse_word_list()
    curw = @ws[@k]
    if curw == '['
      return parse_list
    else
      return parse_word
    end
  end
  def parse_sts_list()
    curw = @ws[@k]
    if curw == '['
      return parse_list
    else
      return parse
    end
  end
  def parse_bool(s)
    return s=='true'
  end
  def is_key(s)
    k=%w[make thing erase isname print read readlinst
                  add sub mul div mod eq gt lt and or not poall
                  random sqrt isnumber isword islist isbool isempty
                  test iftrue iffalse word list join first last erall output
                  butfirst butlast item repeat stop wait save load]
    return k.include? s
  end
  def parse_item(s)
    if is_key(s)
      return s.to_sym
    end
    if s[0]==':'
      return s[1..-1].to_sym
    end
    if s =~ /['"].*/
      return s[1...-1]
    end
    if s =~ /\d+/
      return s.to_i
    end
    return s.to_sym
  end
end