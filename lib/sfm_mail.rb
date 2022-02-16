# frozen_string_literal: true

require 'httparty'

# Service to send transactional email via HTTP to SF Marketingcloud Mail
class SfmMail
  def self.send(mail)
    set_required_props(mail)
    contact_recipient = mail[:to].addresses
    is_multiple_recipient = contact_recipient.length > 1
    api_path = "messaging/v1/messageDefinitionSends/key:#{@api_params[:send_key]}/#{is_multiple_recipient ? 'sendBatch' : 'send'}"
    data = get_recipients_data(contact_recipient, {
                                 SubscriberAttributes: {
                                   BodyContentText: mail.body.raw_source,
                                   Subject: mail.subject
                                 }
                               })
    api_request(api_path, is_multiple_recipient ? data : data[0])
  end

  def self.set_required_props(mail)
    unless Rails.application.config.respond_to?(:sfm_mail_options) && Rails.application.config.sfm_mail_options.present?
      raise 'SfmMail Configuration is missing'
    end

    @api_params = Rails.application.config.sfm_mail_options
    @from_name = mail[:from].display_names[0] || ''
    @from = mail.from[0].gsub(@from_name, '').gsub('\u003c', '').gsub('\u003e', '')
  end

  def self.get_recipients_data(recipients, contact_attrs)
    recipients_data = []
    recipients.each do |recipient|
      recipients_data.push({
                             From: {
                               Address: @from,
                               Name: @from_name
                             },
                             To: {
                               Address: recipient.strip,
                               SubscriberKey: "#{rand(1...9942)}-#{recipient.strip}",
                               ContactAttributes: contact_attrs
                             },
                             Options: {
                               RequestType: 'ASYNC'
                             }
                           })
    end

    recipients_data
  end

  def self.api_request(path, data)
    api_token = api_get_token
    return if api_token.empty?

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{api_token}"
    }

    if data.present?
      HTTParty.post("#{@api_params[:rest_url]}/#{path}",
                    body: data.to_json,
                    headers: headers)
    else
      HTTParty.get("#{@api_params[:rest_url]}/#{path}",
                   headers: headers)
    end
  end

  def self.api_get_token
    auth = HTTParty.post(@api_params[:auth_url],
                         body: {
                           'grant_type' => 'client_credentials',
                           'client_id' => @api_params[:client_id],
                           'client_secret' => @api_params[:client_sec],
                           'scope' => 'email_read email_write email_send'
                         }.to_json,
                         headers: { 'Content-Type' => 'application/json' })

    auth['access_token'].presence || ''
  end
end
