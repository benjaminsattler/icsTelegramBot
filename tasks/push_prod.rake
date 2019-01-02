# frozen_string_literal: true

desc 'Push production image to registries'
multitask push_prod: %w[docker:push_prod gce:push_prod]
