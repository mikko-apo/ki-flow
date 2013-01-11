describe 'Array', ->
  describe '#indexOf()', ->
    it 'should return -1 when the value is not present', ->
      [1,2,3].indexOf(4).should.equal(-1)
    it 'should return index when the value is present', ->
      [1,2,3].indexOf(2).should.equal(1)
