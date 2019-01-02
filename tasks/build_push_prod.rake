# frozen_string_literal: true

desc 'Build a new production image and push it to registries'
task build_push_prod: %w[container:build_prod push_prod]
