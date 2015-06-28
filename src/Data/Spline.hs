-----------------------------------------------------------------------------
-- |
-- Copyright   : (C) 2015 Dimitri Sabadie
-- License     : BSD3
--
-- Maintainer  : Dimitri Sabadie <dimitri.sabadie@gmail.com>
-- Stability   : experimental
-- Portability : portable
--
-- A @Spline s a@ represents a curve in which 'a' is very likely to be
-- 'Additive' (see "linear") and 's' is the sampling type.
--
-- The library exports two useful functions: 'spline' and 'smooth'. The former
-- enables you to create splines while the latter enables you to sample from
-- them using their control points.
----------------------------------------------------------------------------

module Data.Spline (
    -- * Spline
    Spline
  , spline
  , unspline
    -- * Sampling values from splines
  , sample
  ) where

import Data.List ( sortBy )
import Data.Ord ( comparing )
import Data.Spline.CP
import Data.Spline.Polynomial ( Polynomial(..), bsearchLower )
import Data.Vector ( Vector, (!?), fromList, toList )
import qualified Data.Vector as V ( zip )

-- |A @Spline@ is a collection of control points with associated polynomials.
-- Given two control points which indices are /i/ and /i+1/, interpolation on
-- the resulting curve is performed using the polynomial of indice /i/. Thus,
-- the latest control point is ignored and can be set to whatever the user wants
-- to, even 'undefined' – you should use 'hold', though. Yeah, don’t go filthy.
data Spline s a = Spline (Vector (CP s a)) (Vector (Polynomial s a))

-- |Create a spline using a list of control points and associated polynomials.
-- Since 'spline' sorts the list before creating the 'Spline', you don’t have to
-- ensure the list is sorted – even though you should, setting control points
-- with no order might be… chaotic.
spline :: (Ord a,Ord s) => [(CP s a,Polynomial s a)] -> Spline s a
spline = uncurry spline_ . unzip . dupLast . sortBy (comparing fst)
  where
    spline_ cps polys = Spline (fromList cps) (fromList polys)

-- |Deconstruct a 'Spline s a' to yield '[(CP s a,Polynomial s a)]'.
unspline :: Spline s a -> [(CP s a,Polynomial s a)]
unspline (Spline cps polys) = toList $ V.zip cps polys

-- |Sample a point on a spline.
sample :: (Ord s) => Spline s a -> s -> Maybe a
sample (Spline cps polys) s = do
  i <- bsearchLower (\(CP s' _) -> compare s s') cps
  p <- polys !? i
  unPolynomial p s cps

-- Duplicate the last element in a list.
--
-- Warning: unsafe function.
dupLast :: [a] -> [a]
dupLast [] = []
dupLast [x] = [x,x]
dupLast (x:xs) = x : dupLast xs
