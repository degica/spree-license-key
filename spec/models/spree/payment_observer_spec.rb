require 'spec_helper'

describe Spree::PaymentObserver do
  describe '.after_transition' do
    let(:observer) { Spree::PaymentObserver.instance }
    let(:payment) { build_stubbed :payment, :order => order}
    let(:order) { build_stubbed :order }
    let(:transition) { double StateMachine::Transition }
    let(:shipment) { build_stubbed :shipment }

    context "when transition is to shipped" do
      before do
        transition.stub(:to) { "completed" }
        order.stub(:electronic_shipments) { [shipment] }
      end

      context "if the shipment is available to be shipped" do
        before { shipment.stub(:can_ship?) { true } }

        it 'delivers the electronic item' do
          shipment.should_receive(:ship!).once
          observer.after_transition(payment, transition)
        end

        it 'creates a delayed job' do
          Delayed::Worker.delay_jobs = true
          expect { observer.after_transition(payment, transition) }.to change { Delayed::Job.count }.by(1)
          Delayed::Worker.delay_jobs = false
        end
      end
    end
  end
end
