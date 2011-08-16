require 'spec_helper'

remote_describe "transactions testing" do
  require 'torquebox-core'
  include TorqueBox::Injectors

  deploy <<-END.gsub(/^ {4}/,'')
    ---
    application:
      root: #{File.dirname(__FILE__)}/../apps/alacarte/transactions
    ruby:
      version: #{RUBY_VERSION[0,3]}
  END

  it "should not hang when receive times out" do
    input = inject('/queue/input')
    output = inject('/queue/output')
    response = nil
    thread = Thread.new {
      response = output.receive(:timeout => 1)
    }
    input.publish("anything")
    thread.join
    response.should be_nil
  end

  it "should receive a message when no error occurs" do
    input = inject('/queue/input')
    output = inject('/queue/output')
    response = nil
    thread = Thread.new {
      response = output.receive(:timeout => 10_000)
    }
    input.publish("anything")
    thread.join
    response.should_not be_nil
  end

  it "should not receive a message when an error is tossed" do
    pending("publishing works with XASessions")
    input = inject('/queue/input')
    output = inject('/queue/output')
    response = nil
    thread = Thread.new {
      response = output.receive(:timeout => 10_000)
    }
    input.publish("This message should cause an error to be raised")
    thread.join
    sleep 10
    response.should be_nil
  end
end