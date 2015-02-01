require 'set'
require 'readline'
require './reader'

class Mua
  attr_reader :env
  @@prng=Random.new
  def initialize(args={})    
    @make_v=[]
    @user_env={}
    @env={
      :make      => ->(args,ctx;l)     {
                                          l=args[1];ctx[args[0]]=l;@user_env[args[0]]=l;
                                          if l.is_a? Array and l.length==2 and l[0].is_a? Array and l[1].is_a? Array
                                            ctx[:fts].add(args[0])                                          
                                          else
                                            ctx[:vas].add(args[0])
                                          end
                                       },
      :thing     => ->(args,ctx)       {args[0]},
      :':'       => ->(args,ctx)       {ctx[:thing].call(args,ctx)},
      :print     => ->(args,ctx)       {print args[0];puts},
      :add       => ->(args,ctx)       {args[0] + args[1]},
      :sub       => ->(args,ctx)       {args[0] - args[1]},
      :mul       => ->(args,ctx)       {args[0] * args[1]},
      :div       => ->(args,ctx)       {args[0] / args[1]},
      :mod       => ->(args,ctx)       {args[0] % args[1]},
      :eq        => ->(args,ctx)       {args[0] == args[1]},
      :gt        => ->(args,ctx)       {args[0] > args[1]},
      :lt        => ->(args,ctx)       {args[0] < args[1]},
      :and       => ->(args,ctx)       {args[0] and args[1]},
      :or        => ->(args,ctx)       {args[0] or args[1]},
      :not       => ->(args,ctx)       {not args[0]},
      :isempty   => ->(args,ctx)       {args[0].empty?},
      :test_v    => nil,
      :test      => ->(args,ctx)       {ctx[:test_v] = args[0]},      
      :first     => ->(args,ctx)       {args[0][0]},
      :last      => ->(args,ctx)       {args[0][-1]},
      :butfirst  => ->(args,ctx)       {args[0][1..-1]},
      :butlast   => ->(args,ctx)       {args[0][0...-1]},
      :list      => ->(args,ctx)       {args[0]+args[1]},
      :join      => ->(args,ctx)       {args[0]<<args[1]},
      :item      => ->(args,ctx)       {args[1][args[0]]},      
      :output    => ->(args,ctx)       {args[0]},
      :erase     => ->(args,ctx)       {ctx.delete(args[0])},
      :isname    => ->(args,ctx)       {ctx.include?(args[0])},
      :read      => ->(args,ctx)       {Readline.readline('input:',true)},
      :readlinst => ->(args,ctx)       {Readline.readline('input:',true).split},
      :random    => ->(args,ctx)       {@@prng.rand(0...args[0])},
      :sqrt      => ->(args,ctx)       {Math.sqrt(args[0])},
      :isnumber  => ->(args,ctx)       {args[0].is_a? Numeric},
      :isword    => ->(args,ctx)       {args[0].is_a? Symbol},
      :islist    => ->(args,ctx)       {args[0].is_a? Array},
      :isbool    => ->(args,ctx;t)     {!!args[0]==args[0]},
      :repeat    => ->(args,ctx)       {eval(args[0],ctx).times{eval(args[1],ctx)}},
      :local     => ->(args,ctx)       {ctx[args[0]]=nil},      
      :if        => ->(args,ctx)       {eval(args[0],ctx) ? eval(args[1],ctx) : eval(args[2],ctx)},
      :run       => ->(args,ctx)       {eval_list(args[0],ctx)},
      :wait      => ->(args,ctx)       {sleep(args[0]/1000)},
      :save      => ->(args,ctx)       {open(eval(args,ctx),'w').write(Marshal.dump(@user_env))},
      :load      => ->(args,ctx)       {@user_env=Marshal.load(open(eval(args,ctx),'r').read);ctx.merge! @user_env;},
      :erall     => ->(args,ctx)       {ctx=@env_back; @user_env={};},
      :poall     => ->(args,ctx)       {@user_env.each{|k,v| puts "#{k} => #{v}"}},
      :PI        => Math::PI,
      :vas       => Set.new,
      :fts       => Set.new,
      :rv        => nil
    }
    @env_back=@env.dup    
  end  
  def eval(exp,ctx)
    op,*args=exp        
    return apply(op,args,ctx) if op==:make or op==:repeat or op==:if or op==:run
    return eval_list(args[0],ctx) if op==:iftrue or op==:iffalse        
    return eval(ctx[op],ctx) if ctx[:vas].include? op        
    return exp if not ctx.has_key? op
    if ctx[:fts].include? op # special cases
      args = args[0].map{|a| eval(a,ctx);}
    elsif (ctx[op].is_a?(Array) || (ctx[op].respond_to?(:lambda?) && ctx[op].lambda?))
      args = args.map{|a| eval(a,ctx);} 
    end
    apply(op,args,ctx)
  end
  
  def apply(op,args,ctx)
    return eval_func(op,args,ctx) if ctx[:fts].include? op
    tmp=ctx[op].call(Marshal.load(Marshal.dump(args)),ctx)
    tmp
  end
  
  def eval_func(op,args,ctx)    
    eval_list(ctx[op][1].dup,copy_ctx(op,args,ctx))    
  end

  def eval_list(exp_l,ctx)
    ctx[:rv]=nil
    exp_l.each_with_index do |*exp,k|
      op,*args=exp[0]
      if op==:iftrue
        if ctx[:test_v]
          return eval_list(args[0]+exp_l[k+1..-1],ctx)
        else
          next
        end
      end
      if op==:iffalse
        if not ctx[:test_v]
          return eval_list(args[0]+exp_l[k+1..-1],ctx)
        else
          next
        end      
      end
      return ctx[:rv] if op==:stop      
      t=eval(exp[0],ctx)
      ctx[:rv]=t if op==:output
    end
    ctx[:rv]
  end

  def copy_ctx(op,args,ctx)
    c=ctx.merge(Hash[*(ctx[op][0].zip args).flatten(1)])
    c[:vas]=ctx[:vas].dup;c[:fts]=ctx[:fts].dup;c[:vas].merge(ctx[op][0])
    c[:rv]=ctx[:rv].dup if ctx[:rv]!=nil
    c
  end  
end

if ARGV.size<1
  puts "Usage: ruby mua.rb {filename}";
  exit
end
l=Mua.new
reader=Reader.new(ARGV[0])
res=reader.read_list
l.eval_list res,l.env
