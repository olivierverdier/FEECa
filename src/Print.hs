module Print (
   RenderVector(..)--, Pretty(..)
  , printDouble, printComponent, printVector, printVectorColl
  , printPolynomial, printPolynomial0, printForm
  , lambda, dlambda
  ) where

import Text.PrettyPrint
import Text.PrettyPrint.HughesPJ
import Text.Printf
import Spaces
import MultiIndex
import Data.List (intersperse)

-- Some symbols
dlambda = "d\x03BB"
lambda = "\x03BB"
phi = "\x03D5"

class RenderVector v where
    ncomps :: v -> Int
    components :: v -> [Double]

-- | Print Double with precision p and padded to
-- | width w and precision.
printDouble :: Int -> Int -> Double -> Doc
printDouble w p f = text $ printf "%*.*f" w p f

printComponent :: Int -> Int -> Int -> Int -> Double -> Doc
printComponent w p n i f
    | i == 0 = brNW <> printDouble w p f <> brNE
    | i == n-1=  brSW <> printDouble w p f <> brSE
    | otherwise=  brW <> printDouble w p f <> brE

-- | Print vector using precision p for the components
printVector :: RenderVector v => Int -> v -> Doc
printVector p v
    | n <= 1= space <> text (show comps)
    | otherwise = nest 1 $ vcat (zipWith (printComponent maxw p n) [0..n-1] comps)
    where n = ncomps v
          comps = components v
          maxw = maxWidth p comps

printVectorColl :: RenderVector v => Int -> [v] -> Doc
printVectorColl p vs = vcat $ map hsep [[printComponent (ws!!j) p n i ((ls!!j)!!i)
                                        | j <- [0..m-1]]
                                        | i <- [0..n-1]]
    where ls = map components vs
          ws = map (maxWidth p) ls
          m = length vs
          n = minimum (map ncomps vs)

-- | Compute maximum width w required to print components of the vector
-- | at given precision p.
maxWidth :: Int -> [Double] -> Int
maxWidth p l = maximum (map numLen l) + p + 1
    where numLen n
              | n < 0.0   = truncate (logBase 10 n) + 2
              | otherwise = truncate (logBase 10 n) + 1


-- | Pretty print polynomial
printPolynomial :: Integral a => [Char] -> [(Double,MultiIndex)] -> Doc
printPolynomial sym []           = double 0.0
printPolynomial sym [ (c,mon) ]  = double c <+> printMonomial sym (toListMI mon)
printPolynomial sym ((c,mon):ls) = s <+> text "+" <+> printPolynomial sym ls
    where s = double c <+> printMonomial sym (toListMI mon)

-- | Pretty print polynomial
printPolynomial0 :: Integral a => [Char] -> [(Double,MultiIndex)] -> Doc
printPolynomial0 sym []           = double 0.0
printPolynomial0 sym [ (c,mon) ]  = double c <+> printMonomial0 sym (toListMI mon)
printPolynomial0 sym ((c,mon):ls) = s <+> text "+" <+> printPolynomial0 sym ls
    where s = double c <+> printMonomial0 sym (toListMI mon)


-- | Pretty print constant
printConstant :: Double -> Doc
printConstant = double

-- | Pretty print monomial using sym for the components
printMonomial :: [Char] -> [Int] -> Doc
printMonomial sym = printMonomial' sym 1

-- | Pretty print monomial using sym for the components
printMonomial0 :: [Char] -> [Int] -> Doc
printMonomial0 sym = printMonomial' sym 0

printMonomial' :: Integral a => [Char] -> a -> [a] -> Doc
printMonomial' sym i (l:ls)
    | l > 0     = s <> printMonomial' sym (i+1) ls
    | otherwise = printMonomial' sym (i+1) ls
  where s = text sym <> printSub i <> printPower l
printMonomial' _ _ [] = baseD

-- | Print symbol for PrLambdak space
printPrLambdak :: Int -> Int -> Doc
printPrLambdak r k = text "\x1D4DF" <> printSub r <> text "\x039B" <> printSuperscript k

-- | Print symbol for PrMinusLambdak space
printPrMinusLambdak :: Int -> Int -> Doc
printPrMinusLambdak r k = text "\x1D4DF" <> text "\x207B" <> printSub r <> text "\x039B" <> printSuperscript k

-- | Print Whitney form
-- TODO: Print indices > 10 with brackets
printWhitneyForm :: (f -> [Char]) -> [(f,[Int])] -> Doc
printWhitneyForm p ls = hsep $ punctuate (text " + ") (map printPair ls)
  where
    printPair (a,b) = lparen <> text (p a) <> rparen <+> printPhi b
    printPhi ls = text phi <> hcat (map printSub ls)

-- OR: unit as f + apply coeff
printForm :: [Char] -> [Char] -> (f -> [Char]) -> [(f,[Int])] -> Doc
printForm _  unit _     []   = text unit -- $ coeff addId
printForm df _    coeff rest = hsep $ punctuate (text " +") $
  map (\(a,cs) -> text "(" <> (text . coeff) a <> text ")" <+>
                  hsep (intersperse wedgeD (map ((<>) (text df) . printSub) cs)))
      rest


-- * Auxiliary prints

baseD :: Doc
baseD = text ""

-- | Pretty print exponent using unicode superscripts. Prints "" for
-- | 0.
printPower :: Integral a => a -> Doc
printPower i
    | i==2  = text "\x00B2"
    | i==3  = text "\x00B3"
    | i==4  = text "\x2074"
    | i==5  = text "\x2075"
    | i==6  = text "\x2076"
    | i==7  = text "\x2077"
    | i==8  = text "\x2078"
    | i==9  = text "\x2079"
    | i > 9 = printPower (div i 10)  <> printPower (mod i 10)
    | otherwise = text ""
    where ld = truncate (logBase 10 (fromIntegral i))

printSuperscript :: Integral a => a -> Doc
printSuperscript i
    | i==1      = text "\x00B9"
    | otherwise = printPower i

-- | Pretty print subscript using unicode subscripts.
printSub :: Integral a => a -> Doc
printSub i
    | i==0  = text "\x2080"
    | i==1  = text "\x2081"
    | i==2  = text "\x2082"
    | i==3  = text "\x2083"
    | i==4  = text "\x2084"
    | i==5  = text "\x2085"
    | i==6  = text "\x2086"
    | i==7  = text "\x2087"
    | i==8  = text "\x2088"
    | i==9  = text "\x2089"
    | i > 9 = printSub (div i 10)  <> printSub (mod i 10)
    | otherwise = text ""
    where ld = truncate (logBase 10 (fromIntegral i))

wedgeD :: Doc
wedgeD = text "\x2227"

brNW :: Doc
brNW = text "\9121"

brW :: Doc
brW = text "\9122"

brE :: Doc
brE = text "\9125"

brSW :: Doc
brSW = text "\9123"

brNE :: Doc
brNE = text "\9124"

brSE :: Doc
brSE = text "\9126"

brL :: Doc
brL = text "\x005b"

brR :: Doc
brR = text "\x005d"


