require "spec_helper"
require "shipping_agent/slack/notification"

RSpec.describe ShippingAgent::Slack::Notification do
  let(:slack)   { double(:slack, channels_list: channels_list) }
  let(:token)   { "tokenFooBAR" }
  let(:channel) { "#theawsomeones" }
  let(:channels_list) do
    {
      "ok" => true,
      "channels" => [
        {
          "id"        => "FOO",
          "name"      => "foo",
          "is_member" => false,
        },
        {
          "id"        => "BAR",
          "name"      => "bar",
          "is_member" => true,
        },
        {
          "id"        => "BAZ",
          "name"      => "baz",
          "is_member" => true,
        },
      ],
    }
  end
  let(:deploy) do
    double(
      :deploy,
      description: "Make This Awesomes",
      creator: {
        "login" => "errm",
        "avatar_url" => "https://avatars1.githubusercontent.com/u/115280",
        "html_url" => "https://github.com/errm",
      },
    )
  end

  it "posts a message to slack" do
    with_env("SLACK_API_TOKEN" => token) do
      allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

      expected_attachment = {
        text: "the deploy is in progress",
        color: "warning",
        ts: Time.now.to_i,
        mrkdwn_in: ["text"],
      }

      expect(slack).to receive(:chat_postMessage)
        .with(channel: "BAR", attachments: [expected_attachment], as_user: true)

      expect(slack).to receive(:chat_postMessage)
        .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)

      subject.update("pending", "the deploy is in progress", deploy)
    end
  end

  context "when the status is 'request'" do
    it "adds the user specific feilds into the attachment" do
      with_env("SLACK_API_TOKEN" => token) do
        allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

        expected_attachment = {
          title: "Make This Awesomes",
          text: "a deploy was requested",
          author_icon: "https://avatars1.githubusercontent.com/u/115280",
          author_link: "https://github.com/errm",
          author_name: "errm",
          thumb_url: anything,
          color: "warning",
          ts: Time.now.to_i,
          mrkdwn_in: ["text"],
        }

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAR", attachments: [expected_attachment], as_user: true)

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)

        subject.update("request", "a deploy was requested", deploy)
      end
    end
  end

  context "when the status is 'success'" do
    it "posts a message to slack" do
      with_env("SLACK_API_TOKEN" => token) do
        allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

        expected_attachment = {
          text: "the deploy was successful",
          color: "good",
          ts: Time.now.to_i,
          mrkdwn_in: ["text"],
        }

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAR", attachments: [expected_attachment], as_user: true)

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)

        subject.update("success", "the deploy was successful", deploy)
      end
    end
  end

  context "when the status is 'error'" do
    it "posts a message to slack" do
      with_env("SLACK_API_TOKEN" => token) do
        allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

        expected_attachment = {
          text: "the deploy was broken",
          color: "danger",
          ts: Time.now.to_i,
          mrkdwn_in: ["text"],
        }

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAR", attachments: [expected_attachment], as_user: true)

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)

        subject.update("error", "the deploy was broken", deploy)
      end
    end
  end

  context "slack is not configured correctly" do
    it "logs the message and the error and moves on" do
      with_env("SLACK_API_TOKEN" => nil) do
        expect(ShippingAgent::LOGGER).to receive(:warn) do |_args, &block|
          expect(block.call).to eq(
            "Failed to update slack with: the deploy is in progress" \
            ' - due to: KeyError key not found: "SLACK_API_TOKEN"',
          )
        end
        subject.update("pending", "the deploy is in progress", nil)
      end
    end
  end
end
