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
      url: "https://github/deployment/1",
    )
  end

  it "posts a message to slack" do
    with_env("SLACK_API_TOKEN" => token) do
      allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

      expected_attachment = {
        fallback: "the deploy is in progress",
        text: "the deploy is in progress",
        title: "Make This Awesomes",
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
        .and_return(ts: Time.now.to_i)

      expect(slack).to receive(:chat_postMessage)
        .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)
        .and_return(ts: Time.now.to_i)

      subject.update("pending", "the deploy is in progress", deploy)
    end
  end

  context "when the status is 'request'" do
    it "adds the user specific feilds into the attachment" do
      with_env("SLACK_API_TOKEN" => token) do
        allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

        expected_attachment = {
          fallback: "a deploy was requested",
          text: "a deploy was requested",
          title: "Make This Awesomes",
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
          .and_return(ts: Time.now.to_i)

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)
          .and_return(ts: Time.now.to_i)

        subject.update("request", "a deploy was requested", deploy)
      end
    end
  end

  context "when the status is 'success'" do
    it "posts a message to slack" do
      with_env("SLACK_API_TOKEN" => token) do
        allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

        expected_attachment = {
          fallback: "the deploy was successful",
          text: "the deploy was successful",
          title: "Make This Awesomes",
          author_icon: "https://avatars1.githubusercontent.com/u/115280",
          author_link: "https://github.com/errm",
          author_name: "errm",
          thumb_url: anything,
          color: "good",
          ts: Time.now.to_i,
          mrkdwn_in: ["text"],
        }

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAR", attachments: [expected_attachment], as_user: true)
          .and_return(ts: Time.now.to_i)

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)
          .and_return(ts: Time.now.to_i)

        subject.update("success", "the deploy was successful", deploy)
      end
    end
  end

  context "when the status is 'error'" do
    it "posts a message to slack" do
      with_env("SLACK_API_TOKEN" => token) do
        allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

        expected_attachment = {
          fallback: "the deploy was broken",
          text: "the deploy was broken",
          title: "Make This Awesomes",
          author_icon: "https://avatars1.githubusercontent.com/u/115280",
          author_link: "https://github.com/errm",
          author_name: "errm",
          thumb_url: anything,
          color: "danger",
          ts: Time.now.to_i,
          mrkdwn_in: ["text"],
        }

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAR", attachments: [expected_attachment], as_user: true)
          .and_return(ts: Time.now.to_i)

        expect(slack).to receive(:chat_postMessage)
          .with(channel: "BAZ", attachments: [expected_attachment], as_user: true)
          .and_return(ts: Time.now.to_i)

        subject.update("error", "the deploy was broken", deploy)
      end
    end
  end

  context "updating a status" do
    let(:channels_list) do
      {
        "ok" => true,
        "channels" => [
          {
            "id"        => "BAR",
            "name"      => "bar",
            "is_member" => true,
          },
        ],
      }
    end

    def attachment(text, color, ts)
      {
        fallback: text,
        text: text,
        title: "Make This Awesomes",
        author_icon: "https://avatars1.githubusercontent.com/u/115280",
        author_link: "https://github.com/errm",
        author_name: "errm",
        thumb_url: anything,
        color: color,
        ts: ts,
        mrkdwn_in: ["text"],
      }
    end

    it "posts and updates message to slack" do
      with_env("SLACK_API_TOKEN" => token) do
        allow(Slack::Web::Client).to receive(:new).with(token: token).and_return(slack)

        ts = Time.now.to_i

        expect(slack).to receive(:chat_postMessage)
          .with(
            channel: "BAR",
            attachments: [attachment("a deploy was requested", "warning", ts)],
            as_user: true,
          ).and_return("ts" => ts)

        expect(slack).to receive(:chat_update)
          .with(
            channel: "BAR",
            attachments: [attachment("the deploy is in progress", "warning", ts)],
            as_user: true,
            ts: ts,
          ).and_return("ts" => ts)

        expect(slack).to receive(:chat_update)
          .with(
            channel: "BAR",
            attachments: [attachment("the deploy is successful", "good", ts)],
            as_user: true,
            ts: ts,
          ).and_return("ts" => ts)

        subject.update("request", "a deploy was requested", deploy)
        subject.update("pending", "the deploy is in progress", deploy)
        subject.update("success", "the deploy is successful", deploy)
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
