# CCH SFM Mail

This repository contains a simple Ruby gem for integrating Salesforce Marketing Cloud transactional email service via REST API.

## Compatibility

This gem requires **httparty**.

## Installation

Add the following in your Gemfile to link from Github repo:

```
$ gem 'sfm_mail', :git => 'https://github.com/BarefootProximity/sfm-mail-gem.git'
```

Then let's install the bundle:

```
$ bundle install
```

## Authentication

The Salesforce Marketing Cloud API uses your API and Secret keys for authentication. Grab and save your Salesforce Marketing Cloud API credentials by adding them to an initializer.
Values for `your-api-auth-url`,
  `your-api-rest-url`, `your-api-id`, and `your-api-secret` are found in "User Settings" -> "Cloud Preferences". Value for `your-send-key` is found in "Interactions" -> "Triggered Sends (Emails)" -> "External Key" field.

```
# initializers/sfm_mail_service.rb
Rails.application.config.sfm_mail_options = {
  send_key: 'your-send-key',
  rest_url: 'your-api-rest-url',
  auth_url: 'your-api-auth-url',
  client_id: 'your-api-id',
  client_sec: 'your-api-secret'
}
```

## Use the sfm_mail gem in your mailer

The `default_from` is required for sending emails.

```
  default from: "Default Sender <email@domain.com>"

  def contact()
    mail(to: 'contact recipient', subject: 'Your subject here')
  end
```
## Send emails with ActionMailer

First set your delivery method (here Mailjet SMTP relay servers):

```
# application.rb or config/environments specific settings, which take precedence
config.action_mailer.delivery_method = :sfm_mail_delivery
```

Create action mail module

```
# app/lib/mail/sfm_mail_delivery
module CustomMail
  class SfmMailDelivery
    attr_accessor :message

    def initialize(mail); end

    def deliver!(mail)
      api_result = SfmMail.send(mail)
      api_result.present? && api_result['requestId'].present?
    end
  end
end
```

Add the gem to the initializers

```
# initializers/sfm_mail_service.rb
require File.expand_path('../../app/lib/mail/sfm_mail_delivery', __dir__)
ActionMailer::Base.add_delivery_method :sfm_mail_delivery, CustomMail::SfmMailDelivery

Rails.application.config.sfm_mail_options = {
  ...
}
```

Use in custom mailer

```
class ContactMailer < ApplicationMailer
  default from: "Default Sender <email@domain.com>"

  def contact()
    mail(to: 'contact recipient', subject: 'Your subject here')
  end
end
```
