# frozen_string_literal: true

RSpec.describe "Arf::IO::LimitReader" do
  it "#readpartial upto a given size without raising EOF" do
    value = 1.upto(10).to_a.pack("C*")
    data = StringIO.new(value)
    reader = Arf::IO::LimitReader.new(data, 9)
    read = reader.readpartial(9)
    expect(read).to eq value[...9]
  end

  it "#read upto a given size without raising EOF" do
    value = 1.upto(10).to_a.pack("C*")
    data = StringIO.new(value)
    reader = Arf::IO::LimitReader.new(data, 9)
    read = reader.read(9)
    expect(read).to eq value[...9]
  end

  it "accepts multiple calls to #read without raising EOF" do
    value = 1.upto(10).to_a.pack("C*")
    read = StringIO.new
    reader = Arf::IO::LimitReader.new(StringIO.new(value), 9)
    9.times { read.write(reader.read(1)) }
    expect(read.string).to eq value[...9]
  end

  it "accepts multiple calls to #readpartial without raising EOF" do
    value = 1.upto(10).to_a.pack("C*")
    read = StringIO.new
    reader = Arf::IO::LimitReader.new(StringIO.new(value), 9)
    9.times { read.write(reader.readpartial(1)) }
    expect(read.string).to eq value[...9]
  end

  it "returns EOF after the limit is reached" do
    value = 1.upto(10).to_a.pack("C*")
    data = StringIO.new(value)
    reader = Arf::IO::LimitReader.new(data, 9)
    read = reader.readpartial(9)
    expect { reader.readpartial(1) }.to raise_error(EOFError)
    expect { reader.read(1) }.to raise_error(EOFError)
    expect(read).to eq value[...9]
  end
end
