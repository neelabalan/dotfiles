#!/bin/bash

# Array of adjectives
adjectives=(
    "admiring" "adoring" "affectionate" "agitated" "amazing" "angry" "awesome"
    "beautiful" "blissful" "bold" "boring" "brave" "busy" "charming" "clever"
    "cool" "compassionate" "competent" "condescending" "confident" "cranky"
    "crazy" "dazzling" "determined" "distracted" "dreamy" "eager" "ecstatic"
    "elastic" "elated" "elegant" "eloquent" "epic" "exciting" "fervent"
    "festive" "flamboyant" "focused" "friendly" "frosty" "funny" "gallant"
    "gifted" "goofy" "gracious" "great" "happy" "hardcore" "heuristic"
    "hopeful" "hungry" "infallible" "inspiring" "interesting" "intelligent"
    "jolly" "jovial" "keen" "kind" "laughing" "loving" "lucid" "magical"
    "mystifying" "modest" "musing" "naughty" "nervous" "nice" "nifty"
    "nostalgic" "objective" "optimistic" "peaceful" "pedantic" "pensive"
    "practical" "priceless" "quirky" "quizzical" "recursing" "relaxed"
    "reverent" "romantic" "sad" "serene" "sharp" "silly" "sleepy" "stoic"
    "strange" "stupefied" "suspicious" "sweet" "tender" "thirsty" "trusting"
    "unruffled" "upbeat" "vibrant" "vigilant" "vigorous" "wizardly"
    "wonderful" "xenodochial" "youthful" "zealous" "zen"
)

# Array of surnames
surnames=(
    "albattani" "allen" "almeida" "antonelli" "agnesi" "archimedes"
    "ardinghelli" "aryabhata" "austin" "babbage" "banach" "banzai"
    "bardeen" "bartik" "bassi" "beaver" "bell" "benz" "bhabha"
    "bhaskara" "black" "blackburn" "blackwell" "bohr" "booth" "borg"
    "bose" "bouman" "boyd" "brahmagupta" "brattain" "brown" "buck"
    "burnell" "cannon" "carson" "cartwright" "carver" "cerf"
    "chandrasekhar" "chaplygin" "chatelet" "chatterjee" "chebyshev"
    "cohen" "chaum" "clarke" "colden" "cori" "cray" "curran" "curie"
    "darwin" "davinci" "dewdney" "dhawan" "diffie" "dijkstra" "dirac"
    "driscoll" "dubinsky" "easley" "edison" "einstein" "elbakyan"
    "elgamal" "elion" "ellis" "engelbart" "euclid" "euler" "faraday"
    "feistel" "fermat" "fermi" "feynman" "franklin" "gagarin" "galileo"
    "galois" "ganguly" "gates" "gauss" "germain" "goldberg" "goldstine"
    "goldwasser" "golick" "goodall" "gould" "greider" "grothendieck"
    "haibt" "hamilton" "haslett" "hawking" "hellman" "heisenberg"
    "hermann" "herschel" "hertz" "heyrovsky" "hodgkin" "hofstadter"
    "hoover" "hopper" "hugle" "hypatia" "ishizaka" "jackson" "jang"
    "jemison" "jennings" "jepsen" "johnson" "joliot" "jones" "kalam"
    "kapitsa" "kare" "keldysh" "keller" "kepler" "khayyam" "khorana"
    "kilby" "kirch" "knuth" "kowalevski" "lalande" "lamarr" "lamport"
    "leakey" "leavitt" "lederberg" "lehmann" "lewin" "lichterman"
    "liskov" "lovelace" "lumiere" "mahavira" "margulis" "matsumoto"
    "maxwell" "mayer" "mccarthy" "mcclintock" "mclaren" "mclean"
    "mcnulty" "mendel" "mendeleev" "meitner" "meninsky" "merkle"
    "mestorf" "mirzakhani" "moore" "morse" "murdock" "moser" "napier"
    "nash" "neumann" "newton" "nightingale" "nobel" "noether"
    "northcutt" "noyce" "panini" "pare" "pascal" "pasteur" "payne"
    "perlman" "pike" "poincare" "poitras" "proskuriakova" "ptolemy"
    "raman" "ramanujan" "ride" "montalcini" "ritchie" "rhodes"
    "robinson" "roentgen" "rosalind" "rubin" "saha" "sammet"
    "sanderson" "satoshi" "shamir" "shannon" "shaw" "shirley"
    "shockley" "shtern" "sinoussi" "snyder" "solomon" "spence"
    "stonebraker" "sutherland" "swanson" "swartz" "swirles" "taussig"
    "tereshkova" "tesla" "tharp" "thompson" "torvalds" "tu" "turing"
    "varahamihira" "vaughan" "visvesvaraya" "volhard" "villani"
    "wescoff" "wilbur" "wiles" "williams" "williamson" "wilson"
    "wing" "wozniak" "wright" "wu" "yalow" "yonath" "zhukovsky"
)

get_random_name() {
    local adj_index=$((RANDOM % ${#adjectives[@]}))
    local surname_index=$((RANDOM % ${#surnames[@]}))
    
    echo "${adjectives[$adj_index]}_${surnames[$surname_index]}"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    get_random_name
fi
