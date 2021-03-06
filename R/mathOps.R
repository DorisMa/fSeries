
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General 
# Public License along with this library; if not, write to the 
# Free Foundation, Inc., 59 Temple Place, Suite 330, Boston, 
# MA  02111-1307  USA

# Copyrights (C)
# for this R-port: 
#   1999 - 2007, Diethelm Wuertz, GPL
#   Diethelm Wuertz <wuertz@itp.phys.ethz.ch>
#   info@rmetrics.org
#   www.rmetrics.org
# for the code accessed (or partly included) from other R-ports:
#   see R's copyright and license files
# for the code accessed (or partly included) from contributed R-ports
# and other sources
#   see Rmetrics's copyright file


################################################################################
# METHOD:                   MATHEMATICAL OPERATIONS ON DATA:
#  Ops.timeSeries            Returns group 'Ops' for a 'timeSeries' object
#  abs.timeSeries            Returns abolute values of a 'timeSeries' object
#  sqrt.timeSeries           Returns sqrt values of a 'timeSeries' object
#  exp.timeSeries            Returns exponentials of a 'timeSeries' object
#  log.timeSeries            Returns logarithms of a 'timeSeries' object
#  sign.timeSeries           Returns the signs of a 'timeSeries' object
#  diff.timeSeries           Differences a 'timeSeries' object
#  scale.timeSeries          Centers and/or scales a 'timeSeries' object
#  quantile.timeSeries       Returns quantiles of an univariate 'timeSeries'
################################################################################


Ops.timeSeries = 
function(e1, e2 = 1)
{   # A function implemented by Diethelm Wuertz

    # Description:
    #   Uses group 'Ops' generic functions for 'timeSeries' objects
    
    # Arguments:
    #   e1, e2 - two objects of class 'timeSeries'.
    
    # Value:
    #   Returns an object of class 'timeSeries'.
  
    # FUNCTION:
    
    # Save:
    s1 = e1
    s2 = e2
    
    # Which one is a 'timeSeries' object?
    i1 = inherits(e1, "timeSeries")
    i2 = inherits(e2, "timeSeries")
    
    # Match positions and FinCenter?
    if (i1 && i2) {
        if (!identical(as.vector(e1@positions), as.vector(e2@positions))) 
            stop("positions slot must match")
        if (!identical(e1@FinCenter, e2@FinCenter)) 
            stop("FinCenter slot must match") 
    }
            
    # Extract Data Slot:
    if (i1) e1 = e1@Data
    if (i2) e2 = e2@Data   
        
    # Compute:
    s = NextMethod(.Generic)
    
    # Make timeSeries:
    if ( i1)        { s1@Data = s; s = s1 }
    if (!i1 &&  i2) { s2@Data = s; s = s2 } 
    if ( i1 && !i2) s@units = s1@units
    if (!i1 &&  i2) s@units = s2@units
    if ( i1 &&  i2) s@units = paste(s1@units, "_", s2@units, sep = "")
    colnames(s@Data) = s@units
    
    df = data.frame()
    if (i1) {
        if (dim(s1@recordIDs)[1] > 0) 
            df = s1@recordIDs 
    }
    if (i2) {
        if (dim(s2@recordIDs)[1] > 0) 
            df = s2@recordIDs 
    }
    if (i1 & i2) {
        if (dim(s1@recordIDs)[1] > 0 & dim(s2@recordIDs)[1] > 0) 
            df = data.frame(s1@recordIDs, s2@recordIDs)
    }
    s@recordIDs = df
    
    # Return Value:
    s
}
    
    
# ------------------------------------------------------------------------------


abs.timeSeries = 
function(x) 
{   # A function implemented by Diethelm Wuertz
    
    # Description:
    #   Returns absolute values of a 'timeSeries' object
    
    # Arguments:
    #   x - an uni- or multivariate return series of class 'timeSeries'. 

    # Note:
    #   abs is .Primitive
    
    # FUNCTION:
    
    # Absolute Values:
    x@Data = abs(x@Data)
    
    # Return Value:
    x
}


# ------------------------------------------------------------------------------


sqrt.timeSeries = 
function(x) 
{   # A function implemented by Diethelm Wuertz
    
    # Description:
    #   Returns logarithmic values of a 'timeSeries' object
    
    # Arguments:
    #   x - an uni- or multivariate return series of class 'timeSeries'. 
  
    # Note:
    #   sqrt is .Primitive
    
    # FUNCTION:
    
    # Absolute Values:
    x@Data = sqrt(x@Data)
    
    # Return Value:
    x
}


# ------------------------------------------------------------------------------


exp.timeSeries = 
function(x) 
{   # A function implemented by Diethelm Wuertz
    
    # Description:
    #   Returns exponential values of a 'timeSeries' object
    
    # Arguments:
    #   x - an uni- or multivariate return series of class 'timeSeries'. 

    # Note:
    #   exp is .Primitive
    
    # FUNCTION:
    
    # Absolute Values:
    x@Data = exp(x@Data)
    
    # Return Value:
    x
}


# ------------------------------------------------------------------------------


log.timeSeries = 
function(x, base = exp(1)) 
{   # A function implemented by Diethelm Wuertz
    
    # Description:
    #   Returns logarithmic values of a 'timeSeries' object
    
    # Arguments:
    #   x - an uni- or multivariate return series of class 'timeSeries'. 
 
    # Note:
    #   log is .Primitive
    
    # FUNCTION:
    
    # Absolute Values:
    x@Data = log(x@Data, base = base)
    
    # Return Value:
    x
}


# ------------------------------------------------------------------------------


sign.timeSeries = 
function(x)
{   # A function implemented by Diethelm Wuertz

    # Description:
    #   Returns the signs of a 'timeSeries' object
  
    # Arguments:
    #   x - an uni- or multivariate return series of class 'timeSeries'. 
    
    # Note:
    #   sign is .Primitive
    
    # FUNCTION:
    
    # Which sign ?
    x@Data = sign(x@Data)
    
    # Return Value;
    x 
}


# ------------------------------------------------------------------------------


diff.timeSeries = 
function(x, lag = 1, diff = 1, trim = FALSE, pad = NA, ...) 
{   # A function implemented by Diethelm Wuertz

    # Description:
    #   Difference 'timeSeries' objects.
    
    # Arguments:
    #   x - a 'timeSeries' object.
    #   lag - an integer indicating which lag to use. 
    #       By default 1.
    #   diff - an integer indicating the order of the difference.
    #       By default 1.
    #   trim - a logical. Should NAs at the beginning of the
    #       series be removed?
    #   pad - a umeric value with which NAs should be replaced
    #       at the beginning of the series.

    # Value:
    #   Returns a differenced object of class 'timeSeries'.

    # FUNCTION:
        
    # Convert:
    y = as.matrix(x)
        
    # Check NAs:
    # if (any(is.na(y))) stop("NAs are not allowed in time series")
        
    # Difference:
    z = diff(y, lag = lag, difference = diff)

    # Trim:
    if (!trim) {
        diffNums = dim(y)[1] - dim(z)[1]
        zpad = matrix(0*y[1:diffNums, ] + pad, nrow = diffNums)
        rownames(zpad) = rownames(y)[1:diffNums] 
        z = rbind(zpad, z)
    }
      
    # Record IDs:
    df = x@recordIDs
    if (trim) {
        if (sum(dim(df)) > 0) {
            TRIM = dim(df)[1] - dim(z)[1]
            df = df[-(1:TRIM), ]
        }
    }
            
    # Return Value:
    timeSeries(data = z, charvec = rownames(z), units = colnames(z),
        format = x@format, zone = x@FinCenter, FinCenter = x@FinCenter, 
        recordIDs = df, title = x@title, documentation = x@documentation)
}


# ------------------------------------------------------------------------------


scale.timeSeries =
function(x, center = TRUE, scale = TRUE)
{   # A function implemented by Diethelm Wuertz

    # Description:
    #   Centers and/or scales a 'timeSeries' object.

    # Arguments:
    
    # FUNCTION:
    
    # Scale:
    x@Data = scale(x = x@Data, center = center, scale = scale)
    
    # Return Value:
    x
} 


# ------------------------------------------------------------------------------


quantile.timeSeries =      
function(x, ...)
{   # A function implemented by Diethelm Wuertz

    # Description:
    #   Returns quantiles of an univariate 'timeSeries  
    
    # Arguments:
    
    # FUNCTION:
    
    # Check:
    stopifnot(NCOL(x) == 1)
    
    # Quantiles:
    ans = quantile(x = as.vector(x), ...)
    
    # Return Value:
    ans
}    


################################################################################