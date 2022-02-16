# frozen_string_literal: true

require 'httparty'

# Service to send transactional email via HTTP to SF Marketingcloud Mail
class SfmMail
  # before_action :fetch_api_props, only: [:send]

  def self.send(mail)
    fetch_required_props(mail)
    is_multiple = mail[:to].addresses.length > 1
    api_path = 'messaging/v1/messageDefinitionSends/' \
               "key:#{@api_params[:send_key]}/#{is_multiple ? 'sendBatch' : 'send'}"
    data = generate_recipients_data(mail[:to].addresses, {
                                      SubscriberAttributes: {
                                        BodyContentText: mail.body.raw_source,
                                        Subject: mail.subject
                                      }
                                    })
    api_request(api_path, is_multiple ? data : data[0])
  end

  def self.fetch_api_props
    unless Rails.application.config.respond_to?(:sfm_mail_options) && Rails.application.config.sfm_mail_options.present?
      raise 'SfmMail Configuration is missing'
    end

    @api_params = Rails.application.config.sfm_mail_options
  end

  def self.fetch_required_props(mail)
    fetch_api_props
    @from_name = mail[:from].display_names[0] || ''
    @from = mail.from[0].gsub(@from_name, '').gsub('\u003c', '').gsub('\u003e', '')
  end

  def self.generate_recipients_data(recipients, contact_attrs)
    recipients_data = []
    recipients.each do |recipient|
      recipients_data.push({ From: {
                             Address: @from,
                             Name: @from_name
                           }, To: {
                             Address: recipient.strip,
                             SubscriberKey: "#{rand(1...9942)}-#{recipient.strip}",
                             ContactAttributes: contact_attrs
                           }, Options: {
                             RequestType: 'ASYNC'
                           } })
    end

    recipients_data
  end

  def self.api_request(path, data)
    api_token = api_get_token
    return if api_token.empty?

    headers = { 'Content-Type' => 'application/json',
                'Authorization' => "Bearer #{api_token}" }
    if data.present?
      return HTTParty.post("#{@api_params[:rest_url]}/#{path}",
                           body: data.to_json, headers: headers)
    end
    HTTParty.get("#{@api_params[:rest_url]}/#{path}", headers: headers)
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
