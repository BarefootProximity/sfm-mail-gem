require 'httparty'

class SfmMail
  def self.send(mail)
    @from_name = mail[:from].display_names[0] || ''
    @from = mail.from[0].gsub(from_name, '').gsub('\u003c', '').gsub('\u003e', '')

    data = SfmMail.get_recipients_data(contact_recipient, {
                                                   SubscriberAttributes: {
                                                     BodyContentText: mail.body.raw_source,
                                                     Subject: mail.subject
                                                   }
                                                 })
    SfmMail.api_request(api_path, is_multiple_recipient ? data : data[0])
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
      HTTParty.post("#{ENV['SFM_REST_URL']}/#{path}",
                    body: data.to_json,
                    headers: headers)
    else
      HTTParty.get("#{ENV['SFM_REST_URL']}/#{path}",
                   headers: headers)
    end
  end

  def self.api_get_token
    auth = HTTParty.post(ENV['SFM_AUTH_URL'],
                         body: {
                           'grant_type' => 'client_credentials',
                           'client_id' => ENV['SFM_CLIENT_ID'],
                           'client_secret' => ENV['SFM_CLIENT_SECRET'],
                           'scope' => 'email_read email_write email_send'
                         }.to_json,
                         headers: { 'Content-Type' => 'application/json' })

    auth['access_token'].presence || ''
  end
end