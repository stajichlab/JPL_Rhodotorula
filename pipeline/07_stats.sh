#!/usr/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=16 --mem 16gb
#SBATCH --output=logs/stats.%a.log
#SBATCH --time=0:30:00
#SBATCH -p short -J stats

module unload miniconda2
module unload miniconda3
module unload perl
module unload python
module load funannotate/1.8.0

export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
CPUS=$SLURM_CPUS_ON_NODE
OUTDIR=annotate
INDIR=genomes
SAMPFILE=samples2.csv
BUSCO=fungi_odb10

if [ -z $CPUS ]; then
  CPUS=1
fi

N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
  N=$1
  if [ -z $N ]; then
    echo "need to provide a number by --array or cmdline"
    exit
  fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in $SAMPFILE"
  exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read BASER SPECIES STRAIN PHYLUM BIOSAMPLE BIOPROJECT LOCUSTAG
do
  BASE=$(echo -n "$SPECIES $STRAIN" | perl -p -e 's/\s+/_/g')
  STRAIN_NOSPACE=$(echo -n "$STRAIN" | perl -p -e 's/\s+/_/g')
  echo "$BASE"
  MASKED=$(realpath $INDIR/$BASE.masked.fasta)
  if [ ! -f $MASKED ]; then
    echo "Cannot find $BASE.masked.fasta in $INDIR - may not have been run yet"
    exit
  fi
  # need to add detect for antismash and then add that
  funannotate util stats -f $OUTDIR/$BASE/annotate_results/$BASE.scaffolds.fa \
	  -t $OUTDIR/$BASE/annotate_results/$BASE.tbl \
	  --transcript_alignments $OUTDIR/$BASE/predict_misc/transcript_alignments.gff3 \
	  --protein_alignments $OUTDIR/$BASE/predict_misc/protein_alignments.gff3 \
	  -o $OUTDIR/$BASE/annotate_results/$BASE.stats.json
  
done
