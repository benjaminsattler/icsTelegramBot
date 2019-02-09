# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'main_thread'

main = MainThread.new

main.run
