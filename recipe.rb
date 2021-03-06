require 'securerandom'

set :serf_path, "#{recipes_path}/serf"

load "#{serf_path}/roles.rb"
load "#{serf_path}/roles_definitions.rb"
load "#{serf_path}/output.rb"

namespace :serf do

  desc 'Deploy serf on nodes'
  task :default do
    prepare
    install
    handlers::default
    cluster::start
  end

  task :prepare, :roles => [:serf] do
    set :user, "root"
    run "apt-get update 2>/dev/null"
    run "apt-get install -y golang-go 2>/dev/null"
  end

  task :install, :roles => [:serf] do
    set :user, "root"
    run "wget http://public.rennes.grid5000.fr/~msimonin/serf/serf -O /usr/local/bin/serf" 
    run "chmod 744 /usr/local/bin/serf"
  end

  namespace :handlers do

    task :default do
      transfer
    end

    task :transfer, :roles => [:serf] do
      set :user, "root"
      run "mkdir -p /etc/serf"
      upload "#{directory_handlers}", "/etc/serf", :via => :scp, :recursive => true
      run "chmod 755 -R /etc/serf"
    end

  end #namespace handlers

   namespace :cluster do
    
    desc 'Start the serf cluster'    
    task :start do
      agent
      join
    end

    task :agent, :roles => [:serf] do
      set :user, "root"
      pernode = 1
      bind_port_init = bind_port = 10000
      rpc_port_init = rpc_port =  20000
      pernode.times{ |i|
        run "nohup serf  agent
        -node=`hostname`-#{i} 
        -bind=0.0.0.0:#{bind_port} 
        -rpc-addr=0.0.0.0:#{rpc_port}
        -event-handler /etc/serf/handlers/router
        > /tmp/`hostname`-#{i}.log 2>&1 &"
        bind_port = bind_port_init + i
        rpc_port = rpc_port_init + i 
      }
    end

    task :join, :roles => [:serf] do
      set :user, "root"
      nodes = find_servers :roles =>[:serf]
      pernode = 1
      seed = nodes.first
      bind_port_init = bind_port = 10000
      rpc_port_init = rpc_port =  20000
      pernode.times{ |i|
        run "serf join -rpc-addr=0.0.0.0:#{rpc_port} #{seed.host}:#{bind_port_init}"
        rpc_port = rpc_port_init + i 
      }
    end

    desc 'Stop the serf cluster'
    task :stop, :roles => [:serf] do
      set :user, "root"
      run "killall serf"
    end

    desc 'Show members'
    task :stop, :roles => [:serf_first] do
      set :user, "root"
      run "serf members -rpc-addr=0.0.0.0:20000"
    end


  end
end
