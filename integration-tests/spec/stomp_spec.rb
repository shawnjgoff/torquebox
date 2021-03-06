# -*- coding: utf-8 -*-
require 'spec_helper'

require 'fileutils'
require 'torquebox-messaging'

describe "STOMP applications" do

  deploy <<-END.gsub(/^ {4}/,'')
    ---
    application:
      root: #{File.dirname(__FILE__)}/../apps/alacarte/stomp
      env: development
    
    environment:
      BASEDIR: #{File.dirname(__FILE__)}/..

    web:
      context: /stomp-websockets
    
    ruby:
      version: #{RUBY_VERSION[0,3]}
  END

  it "should be able to connect and disconnect using pure stomp" do
    client = Stilts::Stomp::Client.new( "stomp://localhost/" );

    client.connect
    client.disconnect
  end

  it "should be able to connect and disconnect using pure stomp over websockets" do
    client = Stilts::Stomp::Client.new( "stomp+ws://localhost/" );

    client.connect
    client.disconnect
  end


  it "should be able to subscribe" do
    client = Stilts::Stomp::Client.new( "stomp://localhost/" );

    client.connect
    client.subscribe( "/queues/foo" ) do |message|
    end

    sleep( 1 )
    client.disconnect
  end

  it "should be able to subscribe send and receive" do
    client = Stilts::Stomp::Client.new( "stomp://localhost/" );

    client.connect

    received_message = nil

    client.subscribe( "/queues/foo" ) do |message|
      received_message = message
    end

    sleep( 1 )

    client.send( "/queues/foo", "this is my message" )
    sleep( 1 )

    client.disconnect

    received_message.should_not be_nil
    received_message.body.should eql( "this is my message" )
  end

  it "should be able to subscribe send and receive against JMS queues" do
    client = Stilts::Stomp::Client.new( "stomp://localhost/" );

    client.connect

    received_message = nil

    client.subscribe( "/bridge/foo" ) do |message|
      received_message = message
    end

    sleep( 1 )

    client.send( "/bridge/foo", "this is my message" )

    wait_for_condition( 30, 1, lambda { |msg| msg != nil } ) do
      received_message
    end

    client.disconnect

    received_message.should_not be_nil
    received_message.body.should eql( "this is my message" )
  end

  it "should be able to subscribe send and receive against JMS queues, transactionally" do
    client = Stilts::Stomp::Client.new( "stomp://localhost/" );

    client.connect

    received_message = nil

    client.subscribe( "/bridge/bar" ) do |message|
      received_message = message
    end

    sleep( 1 )

    tx = client.begin
    stomp_message = org.projectodd.stilts.stomp::StompMessages.createStompMessage( '/bridge/bar', "this is my message" )
    tx.send( stomp_message )

    sleep( 2 )

    received_message.should be_nil

    tx.commit
    wait_for_condition( 30, 1, lambda { |msg| msg != nil } ) do
      received_message
    end

    client.disconnect

    received_message.should_not be_nil
    received_message.body.should eql( "this is my message" )
  end

  it "should be able to subscribe send and receive utf8 messages" do
    client = Stilts::Stomp::Client.new( "stomp://localhost/" );

    client.connect

    received_message = nil

    client.subscribe( "/queues/foo" ) do |message|
      received_message = message
    end

    sleep( 1 )

    client.send( "/queues/foo", "ääbb" )
    sleep( 1 )

    client.disconnect

    received_message.should_not be_nil
    received_message.body.should eql( "ääbb" )
  end

end

