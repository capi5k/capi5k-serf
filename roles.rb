def role_serf
  $myxp.role_with_name('capi5k-init').servers
end

# all the file inside this directory will be uploaded
def directory_handlers
  "#{serf_path}/handlers"
end

