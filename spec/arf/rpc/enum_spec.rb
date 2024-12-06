# frozen_string_literal: true

RSpec.describe "Arf::RPC::Enum" do
  subject do
    Class.new(Arf::RPC::Enum) do
      option one: 1
      option two: 2
      option three: 3
      option tre: 3
    end
  end

  context "#to_i" do
    it "coerces symbols to integers" do
      expect(subject.to_i(:tre)).to eq 3
    end

    it "lets integers pass-through" do
      expect(subject.to_i(3)).to eq 3
    end

    it "coerces strings to integers" do
      expect(subject.to_i("tre")).to eq 3
    end

    it "rejects other types" do
      expect { subject.to_i({ tre: true }) }.to raise_error(ArgumentError)
        .with_message("Invalid value type Hash. Expected Symbol, String or Integer.")
    end
  end

  context "#to_sym" do
    it "coerces integers to symbols" do
      expect(subject.to_sym(3)).to eq :three
    end

    it "coerces strings to symbols" do
      expect(subject.to_sym("tre")).to eq :tre
    end

    it "lets symbols pass-through" do
      expect(subject.to_sym(:tre)).to eq :tre
    end

    it "rejects other types" do
      expect { subject.to_sym({ tre: true }) }.to raise_error(ArgumentError)
        .with_message("Invalid value type Hash. Expected Symbol, String or Integer.")
    end
  end
end
