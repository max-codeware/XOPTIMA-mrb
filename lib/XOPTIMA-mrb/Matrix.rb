# Copyright (c) 2020, Massimiliano Dal Mas
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the distribution
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

module XOPTIMA

	##
	# Lightweight implementation of matrix class for
	# internal use. This is to maintain compatibility
	# with both Ruby and Mruby
  class Matrix 
    
    ##
    # It creates an identity matrix of the given size
    def self.identity(d)
    	rows = Array.new(d) { |i| Array.new(d) { |j| i == j ? 1 : 0} }
      new rows
    end

    ##
    # It creates an empty matrix but recording the dimensions
    def self.empty(r,c)
      new [], r, c 
    end

    ##
    # Same as new([[], ..]), but just pass the rows as
    # parameter
    def self.[](*rows)
      new rows
    end

    ##
    # It creates a new matrix.
    #
    # Parameters:
    #  * rows: array of arrays containing the matrix saved as row magnitude
    #  * r: number of rows. This is used only if the matrix is empty
    #  * c: number of columns. This is used only if the matrix is empty
    def initialize(rows, r = nil, c = nil)
      raise ArgumentError, "Expected array, but #{rows} found" unless rows.is_a? Array
      rows.each do |r|
      	raise ArgumentError, "Expected array, but #{r} found" unless r.is_a? Array
      end
      if rows.empty? 
        raise TypeError, "number of rows is expected to be an integer, not #{r.class}" unless r.is_a? Integer
        raise TypeError, "number of columns is expected to be an integer, not #{c.class}" unless c.is_a? Integer
        @r = r 
        @c = c 
      else
        @r = rows.size
        @c = rows.first.size
      end
      rows.each do |r| 
      	raise ArgumentError, "Inconsistent matrix detected" unless r.size == @c 
      end 
      @rows = rows
      Check.ensure_symbolic self
    end

    ##
    # It returns the number of rows
    def rows 
      @r
    end

    ##
    # It returns the number of columns
    def columns 
      @c
    end

    ##
    # It performs the matrix product between this matrix and
    # another one or a vector (saved as a simple array)
    def *(b)
      Check.ensure_symbolic b
      Check.matrix_product self, b
      case b 
      when Array
        __column_vector_prod(b) 
      when Matrix 
        __matrix_prod(b)
      else
        map { |v|  v * b}
      end
    end
    

    ##
    # It access the (i, j)th element of the matrix
    def [](i,j)
      return @rows[i][j]
    end

    # It transposes the matrix
    def transpose
      return Matrix.new @rows.transpose
    end

    def map
      r = @rows.map do |row|
        row.map do |v|
          yield v 
        end 
      end 
      Matrix.new(r)
    end

    def map!
      r = @rows.map! do |row|
        row.map! do |v|
          yield v 
        end 
      end 
      self 
    end

    def each
      @rows.each do |row|
        row.each do |v|
          yield v 
        end 
      end 
      nil 
    end

    def each_with_index
      @rows.each_with_index do |row, i|
        row.each_with_index do |v, j|
          yield v, i, j 
        end 
      end 
      nil 
    end

    def to_s 
    	"Matrix#{@rows}"
    end

    ##
    # It converts this matrix to a sparse one using
    # the `SparseMatrix` class
    def to_sparse(label = nil)
      sparse_elems = []
      self.each_with_index do |v, i, j|
        sparse_elems << [i, j, v] if v != 0
      end
      return SparseMatrix.new(rows, columns, sparse_elems, label: label)
    end

  private 

    def __column_vector_prod(v)
      @rows.map do |row| 
        b = 0 
        row.each_with_index do |a, i|
          b += a * v[i]
        end
        b
      end
    end

    def __matrix_prod(m)
      r = @rows.map do |row|
        nr = Array.new(m.columns)
        m.columns.times do |k|
          b = 0
          row.each_with_index do |v, i|
            b += v * m[i, k]
          end
          nr << b
        end
        nr
      end
      Matrix.new(r)
    end

  end

  ##
  # This class represents a sparse representation of a matrix.
  # This is an ad-hoc representation for this library.
  # The non-zero elements are saven in an array as a vector
  # containing, in the order, the row, the column and the value.
  class SparseMatrix

    attr_reader :rows, :cols, :label
    
    ##
    # Parameters:
    #   * rows: number of rows of the sparse matrix
    #   * cols: number of columns of the sparse matrix
    #   * nz:   array with the non-zero elements representation
    #   * label: name given to this matrix (used in file generation)
    def initialize(rows, cols, nz, label: nil)
      @rows  = rows
      @cols  = cols
      @label = label 
      @nz    = nz
    end

    def each_value
      @nz.each do |*_, v|
        yield v 
      end 
    end

    ##
    # It iterates over the elements passing to the given
    # block:
    #  * row number
    #  * column number
    #  * value
    def each_value_with_index
      @nz.each do |i, j, v|
        yield v, i, j
      end
    end
    
    ##
    # It returns the number of non-zero elements
    def nnz
      @nz.size 
    end

    ##
    # It returns the pattern of the non-zero elements
    def pattern
      @nz.map { |nz_cell| nz_cell[0..1] }
    end

    # def to_erb
    # end
  end
end