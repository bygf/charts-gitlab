# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Annotations configuration' do
  let(:default_values) do
    {
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      'gitlab' => { 'kas' => { 'enabled' => 'true' } }, # DELETE THIS WHEN KAS BECOMES ENABLED BY DEFAULT
      'global' => { 'deployment' => { 'annotations' => { 'environment' => 'development' } } }
    }
  end

  let(:ignored_charts) do
    [
      'Deployment/test-cainjector',
      'Deployment/test-cert-manager',
      'Deployment/test-gitlab-runner',
      'Deployment/test-prometheus-server'
    ]
  end

  context 'When setting global deployment annotations' do
    it 'Populates annotations for all deployments' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      resources_by_kind = t.resources_by_kind('Deployment').reject { |key, _| ignored_charts.include? key }

      resources_by_kind.each do |key, _|
        expect(t.annotations(key)).to include(default_values['global']['deployment']['annotations'])
      end
    end
  end

  context 'When configuring EKS IRSA annotation', :focus => true do
    let(:irsa_annotations) do
      YAML.safe_load(%(
        global:
          serviceAccount:
            enabled: true
            create: false
            name: aws-role-sa
          platform:
            eksRoleArn: "arn:aws:iam::1234567890:role/eks-fake-role-arn"
      )).deep_merge(default_values)
    end
    annotation_key = 'eks.amazonaws.com/role-arn'

    it 'Populates eks.amazonaws.com/role-arn annotation' do
      t = HelmTemplate.new(irsa_annotations)
      expect(t.exit_code).to eq(0)

      expect(t.template_annotations('Deployment/test-task-runner')[annotation_key]).to eq('arn:aws:iam::1234567890:role/eks-fake-role-arn')
      expect(t.template_annotations('Deployment/test-webservice-default')[annotation_key]).to eq('arn:aws:iam::1234567890:role/eks-fake-role-arn')
      expect(t.template_annotations('Deployment/test-sidekiq-all-in-1-v1')[annotation_key]).to eq('arn:aws:iam::1234567890:role/eks-fake-role-arn')
    end
  end
end
