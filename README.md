# postman

这里是邮局，谢谢。

目前支持以下几种投递方式:

1. Long pull
2. Comet
3. Websocket

## Websocket模式

* 执行seed.rb
* 浏览器A打开：`http://42.121.89.18:8000/websocket?user_credentials=035c6c3040830130a6f200163e0218fd`
* 浏览器B打开：`http://42.121.89.18:8000/websocket?user_credentials=0360d0f040830130a6f200163e0218fd`
* 浏览器C打开：`http://42.121.89.18:8000/websocket?user_credentials=036322f040830130a6f200163e0218fd`
* 浏览器A的to字段设置消息接受者ID，可以设置多个ID，通过`,`分隔
* 浏览器A发送消息给to字段的接受者B和C，to字段值为`1234567890,09ngdfsd4321`，回车发送数据
* 浏览器B和C将收到A发过来的数据

A发送的数据为:

	{
		to : '1234567890,09ngdfsd4321', 
		content : 'hello world'
	}

B,C接收到的数据位:

	{
		from : '0987654321', 
		content : 'hello world'
	}

## Contributing to postman
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 zheng.cuizh. See LICENSE.txt for
further details.

