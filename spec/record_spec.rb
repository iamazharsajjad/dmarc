require 'spec_helper'
require 'dmarc/record'

describe Record do
  context 'by default' do
    it 'has a relaxed DKIM alignment' do
      expect(subject.adkim).to eq(:r)
    end

    it 'has a relaxed SPF alignment' do
      expect(subject.aspf).to eq(:r)
    end

    it 'has failure reporting options of "0"' do
      expect(subject.fo).to eq(['0'])
    end

    it 'has an application percentage of 100' do
      expect(subject.pct).to eq(100)
    end

    it 'has an afrf report format' do
      expect(subject.rf).to eq(:afrf)
    end

    it 'has a report interval of 1 day' do
      expect(subject.ri).to eq(86400)
    end
  end

  describe '#initialize' do
    let(:attributes) do
      {
        v: :DMARC1,
        p: :none,
        adkim: :r
      }
    end

    subject { described_class.new(attributes) }

    it 'assigns the fields to its properties' do
      expect(subject.v).to     be :DMARC1
      expect(subject.p).to     be :none
      expect(subject.adkim).to be :r
    end

    it 'gives "sp" the same value as "p" if undefined' do
      expect(subject.sp).to be :none
    end
  end

  describe '.parse' do
    subject { described_class }

    context 'with a valid record' do
      it 'parse and returns a record' do
        rec = subject.parse('v=DMARC1; p=quarantine')

        expect(rec).to be_a Record
        expect(rec.p).to eq :quarantine
      end
    end

    context 'with an invalid record' do
      it 'raises an InvalidRecord error' do
        expect { subject.parse('v=DMARC1; foo=bar') }.to raise_error do |error|
          expect(error).to be_a InvalidRecord
          expect(error.ascii_tree).to_not be_nil
        end
      end
    end
  end

  describe ".query" do
    subject { described_class }

    context "when given a domain" do
      let(:domain) { 'google.com' }

      it "should query and parse the DMARC record" do
        record = subject.query(domain)

        expect(record).to be_kind_of(Record)
        expect(record.v).to be == :DMARC1
      end
    end

    context "when given a bad domain" do
      it "should raise a DNS error" do
        expect(subject.query('foobar.com')).to be_nil
      end
    end
  end

  describe "#to_s" do
    let(:v) { :DMARC1 }
    let(:p) { :reject }
    let(:rua) { [URI.parse('mailto:d@rua.agari.com')] }
    let(:ruf) { [URI.parse('mailto:d@rua.agari.com')] }
    let(:fo)  { %w[0 1 d] }

    subject do
      described_class.new(
        v: v,
        p: p,
        rua: rua,
        ruf: ruf,
        fo: fo
      )
    end

    it "should convert the record to a String" do
      expect(subject.to_s).to be == "v=#{v}; p=#{p}; rua=#{rua[0]}; ruf=#{ruf[0]}; fo=#{fo[0]}:#{fo[1]}:#{fo[2]}"
    end
  end
end
