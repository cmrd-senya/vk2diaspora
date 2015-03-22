vk2diaspora
===========

Simple script to transfer entries from vk.com public pages to diaspora* network

Prerequisites
-------------

  1. Ruby 1.9.3
  2. Ruby Gem 'vkontakte_api' installed (tested with v. 1.4)
  3. Ruby Gem 'diaspora-api' installed (at least 0.0.4)
  
Usage
-----

Command syntax is following:
```
$ vk2diaspora.rb -v <pagename> -d <name@pod.host> -a <aspectname> -p <password> [options]
```

For example, you could run the following to transfer entries from https://vk.com/anons_rev to your diaspora account yourname@diasp.eu "test" aspect:
```
$ vkdiaspora -v anons_rev -d yourname@diasp.eu -a test -p MyPassWord -t "#vk2diaspora"
```

Additional tags (-t option) will be appended as a last line of your post. 

Use the word "public" for aspect to post your entries available for view by everyone.

The script will create directory ~/vk2diaspora.timestamps to store timestamps of last posted entry (taken from vk.com API answer). So if you rerun script, it will transfer only that entries, which are newer than this timestamp. It makes possible to continue post transfer as the parent public page updates.

