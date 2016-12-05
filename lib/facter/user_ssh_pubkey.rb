# Fact: <username>_ssh(rsa|dsa)key,
#       <username>_ssh(rsa|dsa)key_comment,
#       <username>_ssh(rsa|dsa)key_type
#
# Purpose:
#   Collect users' SSH public keys (presumably for exported resources).
#
# Resolution:
#   Reads a list of user names from *user_ssh_pubkey* fact and creates Facts
#   of their keys. The *user_ssh_pubkey* fact can be set with an external fact.
#

require 'etc'

module Facter::UserSshPubkey

  def self.add_facts_for_user(username)
    Facter.debug("Looking for SSH keys for user '#{username}'")
    user = Etc.getpwnam(username)
    sshdir = File.join(user.dir, '.ssh')

    [ 'rsa', 'dsa' ].each do |keytype|
      pubfile = "id_#{keytype}.pub"
      pubpath = File.join(sshdir, pubfile)

      if FileTest.exists?(pubpath)
        Facter.debug("Found '#{pubpath}' for user '#{username}'")
        ktype, key, comment = File.read(pubpath) \
          .chomp.split($;, 3)
        fact_base = "#{username}_ssh#{keytype}key"

        Facter.add(fact_base) do
          Facter.debug("Setting '#{fact_base}' to '#{key}'")
          setcode { key }
        end

        Facter.add("#{fact_base}_comment") do
          setcode { comment }
        end

        Facter.add("#{fact_base}_type") do
          setcode { ktype }
        end
      else
        Facter.debug("Did not find '#{pubpath}' for user '#{username}'")
      end
    end
  end

  def self.add_facts
    users_fact = Facter.value('user_ssh_pubkey')
    Facter.debug("'users_fact' is '#{users_fact}'")
    users = users_fact ? users_fact.split(',') : []

    users.each { |user| Facter::UserSshPubkey.add_facts_for_user(user) }
  end
end
Facter::UserSshPubkey.add_facts
