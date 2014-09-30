vk2diaspora
===========

Simple script to transfer entries from vk.com public pages to diaspora* network

Prerequisites
-------------

  1. Ruby 1.9.3
  2. Ruby Gem 'vkontakte_api' installed (tested with v. 1.4)
  3. Cliaspora [1] (tested with v. 0.1.9)
  
Usage
-----

This script uses Cliaspora [1] to make posts to d* network. vk2diaspora script assumes, that you have set up session with Cliaspora in the following way:

$ cliaspora session new yourname@diasp.eu

It will ask you of your password and will save session cookie.

Now you could use vk2diaspora. Command syntax is following:
```
$ vk2diaspora <vk page short address> <diaspora account> <diaspora aspect> [additional tags]
```

For example, you could run the following to transfer entries from https://vk.com/anons_rev to your diaspora account yourname@diasp.eu "test" aspect:

$ vkdiaspora anons_rev yourname@diasp.eu test "#vk2diaspora"

Additional tags will be appended as a last line of your post. 

Use the word "public" for aspect to post your entries available for view by everyone.

The script will create directory ~/vk2diaspora.timestamps to store timestamps of last posted entry (taken from vk.com API answer). So if you rerun script, it will transfer only that entries, which are newer than this timestamp. It makes possible to continue post transfer as the parent public page updates.

[1] https://freeshell.de//~mk/projects/cliaspora.html

