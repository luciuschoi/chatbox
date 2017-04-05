# 레일스용 웹소켓 : 액션케이블

일반적으로 웹애플리케이션은 HTTP 통신 프로토콜을 이용하여 서버와 클라이언트 간의 단방향 통신(half-duplex communication)을 이용하여 서비스를 한다. 따라서 채팅 프로그램을 웹으로 구현할 때는 데이터의 동시성에 관한 문제를 해결하기 실무적으로 어렵게 되고 기존에는 대안으로 일정한 시간 간격으로 서버에서 클라이언트로 데이터를 보내는 `polling` 방식을 사용한다.

DHH는 이러한 `polling` 방식의 문제점을 해결하기 위해 양방향 동시 통신을 가능케 해 주는 웹소켓을 레일스 프레임워크에서 레일스 방식으로 쉽게 구현할 수 있도록 했는데 이것을 `액션케이블(ActionCable)`이라고 한다. 레일스 5.0에 처음으로 도입되었다.



### 서버단(Server-side)

사용자의 요청이 서버로 올 때 레일스는 웹소켓 통신 환경을 설정하고 서버와 클아이언트 사이에 통신 채널을 생성하여 이 후 양방향 통신(full duplex communication)이 가능하도록 한다.



### 클라이언트단(Client-side)

이후 반복적으로 사용자의 요청이 서버로 도달할 때마다, 서버에서 해당 요청에 대한 작업을 완료한 후 그 결과를 같은 채널을 구독(`subscribe`)하고 있는 클라이언트로 보내게 되는데 이 과정을 `broadcast` 라고 한다.



### Chatbox 웹애플리케이션 생성

```shell
$ rails new chatbox
```



#### 1. 루트 라우트 셋업

랜딩 페이지(landing page) 또는 홈 페이지를 만들기 위해 `welcome` 컨트롤러를 생성하고 `index` 액션을 추가한다.

> **노트** : 컨트롤러 이름과 액션 이름은 임의로 정해도 된다. 예를 들어 `pages` 컨트롤러에 `home` 액션을 추가할 수 있다. 동적 데이터가 필요없는 정적 페이지를 쉽게 사용할 수 있게 해 주는 [`high_voltage`](https://github.com/thoughtbot/high_voltage) 라는 젬도 있으니 한번 사용해 보기 권한다.

```shell
$ rails g controller welcome index
```

커맨드라인에서 위의 명령을 실행한 후 `config/routes.rb` 파일을 에디터로 연 후, 루트 라우트를 `welcome#index`로 지정한다.

```ruby
root "welcome#index"
# get "welcome/index”
```

> **주의** : "welcome#index" 문자열의 가운데 문자가 슬래시가 아니고 # 문자임을 확인한다.



#### 2. 웹페이지 UI 작성을 위한 준비

웹페이지의 UI를 손쉽게 작성하기 위해 몇가지 유용한 젬을 먼저 설치한다. `Gemfile`을 열고 아래와 같이 추가한다. 삽입할 위치는 어디에 두어도 상관이 없다.

```ruby
gem 'bootstrap', '~> 4.0.0.alpha6'
source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
end
gem 'toastrjs-rails'
gem 'simple_form'
gem 'devise'

# 중간 생략 ~
```

그리고 젬을 설치한다.

```shell
$ bundle install
```

이후 각 젬을 이용하기 위한 환경설정법은 해당 젬의 문서를 참조한다. 각 라인을 복사해서 구글 검색하면 쉽게 찾아 볼 수 있다.



##### bootstrap 젬의 설정

application.css 파일명을 application.scss 로 변경하고 기존 내용을 모두 삭제한 후 아래와 같이 추가한다.

```scss
@import 'bootstrap';
```

application.js 파일을 열고 아래와 같이 2, 3번 코드라인을 추가한다.

```javascript
//= require jquery
//= require tether
//= require bootstrap
//= require jquery_ujs
//= require turbolinks
//= require_tree .
```



##### toastrjs-rails 젬의 설정

application.scss 파일을 열고 아래와 같이 2번 라인을 추가한다.

```scss
@import 'bootstrap';
@import 'toastr.min';
```

이어서 application.js 파일을 열고 아래와 같이 5번 코드라인을 추가한다.

```javascript
//= require jquery
//= require tether
//= require bootstrap
//= require jquery_ujs
//= require toastr.min
//= require turbolinks
//= require_tree .
```

그리고 `app/helpers/application_helper.rb` 파일을 열고 아래와 같이 헬퍼메소드를 추가한다.

```ruby
module ApplicationHelper

  def flash_toastr
    flash_messages = []
    flash.each do |type, message|
      type = 'success' if type == 'notice'
      type = 'error'   if type == 'alert'
      text = "<script>toastr.#{type}('#{message}','',{ 'closeButton': true });</script>"
      flash_messages << text.html_safe if message
    end
    flash_messages.join("\n").html_safe
  end

end
```

이제 뷰 파일의 플래시 메시지를 표시할 위치에 아래와 같이 추가하면 된다.

```erb
# 중간 생략 ~

<%= flash_toastr %>

# 중간 생략 ~
```

자바스크립트에서의 `toastr` 라이브러리에 대한 자세한 사용법은 [이 곳](https://github.com/CodeSeven/toastr)을 참고하면 된다.



##### simple_form 젬의 설정

이 젬은 별도의 폼 입력 헬퍼메소드를 제공해 주며 bootstrap 과 함께 사용하면 간단한 syntax를 작성하여 복잡한 bootstrap 관련 코드를 대신할 수 있게 해 준다.

```shell
$ rails g simple_form:install --bootstrap
```



#### 3. 사용자 인증

##### devise 젬의 설정

`devise` 젬을 사용하여 사용자 인증을 구현한다. 이를 위해서 아래와 같은 일련의 명령을 실행한다.

```shell
$ rails g devise:install
$ rails g devise User
$ rails g devise:views
$ rake db:create
$ rake db:migate
```

더 자세한 사용법은 [해당 문서](https://github.com/plataformatec/devise)를 참고한다.

`config/environments/development.rb` 파일을 열고 아래와 같이 추가한다.

```ruby
...

config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }		
```



##### 인증 링크 추가

이제 `views/welcome/index.html.erb`  파일을 열고 아래와 같이 작성한다.

```erb
<h1>Welcome to ChatBox</h1>

<% if user_signed_in? %>
  <%= current_user.email %> |
  <%= link_to "Sign-out", destroy_session_path(current_user), method: :delete, data: { confirm: "Are you sure?"} %>
  <hr>
  <%= link_to "Enter ChatBox", "", class: 'btn btn-outline-primary' %>
<% else %>
  <%= link_to "Sign-in", new_user_session_path, class: 'btn btn-outline-primary' %>
<% end %>
```

회원가입과 로그인 절차를 가능하게 해 준다.



#### 4. 액션케이블 작성

이를 위해서 아래와 같이 `chatting`이라는 채널을 생성한다.

```shell
$ rails g channel chatting
Running via Spring preloader in process 42928
      create  app/channels/chatting_channel.rb
   identical  app/assets/javascripts/cable.js
      create  app/assets/javascripts/channels/chatting.coffee
```

이로써 서버단(3번 코드라인)과 클라이언트단(5번 코드라인)용 `channels` 폴더가 생성되고 각 채널 폴더에 `chatting_channel.rb`  파일과 `chatting.coffee` 파일이 생성된다.



##### 서버단 디렉토리 구조

```shell
$ tree app/channels/
app/channels/
├── application_cable
│   ├── channel.rb
│   └── connection.rb
└── chatting_channel.rb

1 directory, 3 files
```



사용자로부터 최초로 액션케이블에 대한 연결 요청이 있을 때 아래와 같이 두개의 콜백 메소드를 정의할 수 있다.

`app/channels/chatting_channel.rb`

```ruby
class ChattingChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
```

여기서 3번 코드라인을 아래와 같이 수정한다. 채널명은 임의로 정할 수 있다. 통상 아래와 같이 앞서 사용할 채널이름에 `_channel` 문자열을 붙여서 사용한다.

```ruby
stream_from 'chatting_channel'
```

이제, 채팅시 작성한 글을 서밋하여 데이터베이스에 글을 저장한 후 액션케이블 서버에서 글 내용을 `broadcast`하면 된다. 이 때 보내지는 글 내용을 클라이언트 브라우저에서 data 해시값으로 받게 된다. 따라서 이 data 해시값이 위의 `received` 콜백함수의 파라메터로 받게되는 것이다.

이를 위해서 아래와 같이 `Message` 라는 모델을 가지는 리소스를 **scaffold 제너레이터** 로 생성한다.

```shell
$ rails g scaffold Message content:text user:references
$ rake db:migrate
```

이 때 생성된 컨트롤러 파일을 열고 아래와 같이 `create` 메소드를 수정한다.

`app/controllers/messages_controller.rb`

```ruby
class MessagesController < ApplicationController
  before_action :authenticate_user!

  # 중간 생략 ~

  def create
    @message = Message.new(message_params)
    @message.user = current_user

    respond_to do |format|
      if @message.save
        ActionCable.server.broadcast 'chatting_channel', content: @message.content, message_user: @message.user
        format.js { head :ok }
      else
        format.html { render :new }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # 중간 생략 ~

end  
```

메시지를 저장한 후, 액션케이블 서버의 `broadcast` 메소드를 이용하여 이 채널을 구독하는 모든 사용자들의 브라우저로 메시지를 전달한다. (12번 코드라인)

이 때 클라이언트에서는 `content`와 `message_user` 값을 `data` 해쉬키로 접근할 수 있게 된다.



##### 클라이언트단 디렉토리 구조

```shell
$ tree app/assets/javascripts/channels
app/assets/javascripts/channels
└── chatting.coffee
```

클라이언트 코딩은 coffeescript로 작성한다. `app/assets/javascripts/channels/chatting.coffee` 파일을 열고 아래와 같이 코드를 추가한다. (10 ~ 13번 코드라인)

```coffeescript
App.chatting = App.cable.subscriptions.create "ChattingChannel",
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    unless data.content.blank?
      $('#messages').append "<li>" + data.message_user.email + " : " + data.content + "</li>"
      $('#message_content').value ""
      $('#messages').scrollTop $('#messages')[0].scollHeight
```

이미 언급한 바와 같이 `received` 콜백함수로 넘겨지는 `data` 파라메터는 액션케이블 서버에서 `broadcast` 하는 데이터이다.

채팅방은 `messages` 컨트롤러의 `index` 액션 뷰 페이지를 아래와 같이 작성한다.

`views/messsages/index.html.erb`

```erb
<h1>Messages</h1>

<ul id='messages'>
  <%= render @messages %>
</ul>

<br>

<%= render 'form' %>

```

그리고 `views/messages/_message.html.erb` 파일을 생성하고 아래와 같이 작성한다.

```erb
<li><%= message.content %></li>
```

또한 폼 파셜(`views/messages/_form.html.erb`)을 아래와 같이 수정한다.

```html
<%= simple_form_for(@message, remote: true) do |f| %>
  <%= f.error_notification %>

  <div class="form-inputs">
    <%= f.input :content, label: false %>
  </div>

  <div class="form-actions">
    <%= f.button :submit %>
  </div>
<% end %>
```

여기서 주목할 것은 `form_for` 메소드에 `remote` 파라미터를 `true`로 추가했다는 것이다. 또한 메시지를 입력의 편리성을 위해서 submit 버튼을 없애고 아래와 같이 엔터키를 눌러 메시지를 서밋할 수 있게 한다. 따라서 위의 코드라인 9~11 을 삭제한다.

`app/assets/javascripts/messages.coffee`

```coffeescript
$(document).on "turbolinks:load", ->
  $("#messages").scrollTop $("#messages")[0].scrollHeight
  $('#message_content').on 'keydown', (event) ->
    if event.keyCode is 13 && !event.shiftKey
      $('input').click()
      event.target.value = ''
      event.preventDefault()
```

3번 코드라인 같이 시프트키를 사용하여 줄 바꿈을 할 수 있도록 옵션을 추가했다.

다음은 `assets/stylesheets/messages.scss` 파일을 열고 아래와 같이 작성한다.

```scss
#messages {
  border: 1px solid #ccc;
  height: 25em;
  padding: 1em;
  overflow: auto;
  list-style-type: none;
}

#new_message {
  input[type=submit]{
    display: none;
  }
}

#new_user {
  margin-bottom: 2em;
}
```

9~13 코드라인은 메시지 입력폼의 서밋 버튼이 더 이상 필요 없기 때문에 보이지 않도록 하기 위한 것이다.



#### 5. 브라우저에서 확인하기

브라우저를 열고 http://localhost:3000 으로 접속하고 사용자 등록후 로그인한다. 또 다른 브라우저를 열 때 크롬 브라우저의 경우에는 브라우저 상단의 ` 파일` > `새 시크릿창(⇧⌘N)` 메뉴를 선택한다. 그리고 또 다른 사용자를 추가 등록한 후 해당 사용자로 로그인하여 두 사용자가 로그인한 상황을 연출한다.

>  **참고** : 사파리 브라우저의 경우에는 `파일` > `새로운 개인 정보 보호 윈도우(⇧⌘N)` 메뉴를 선택한다.

이제 각각의 브라우저에서 메시지를 입력한 후 엔터키를 눌러 본다.

Voila~
