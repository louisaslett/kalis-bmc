# Input data can be sourced from https://www.internationalgenome.org/

# use bcftools to extract regions
# this 1k genome data is in hg19 coordinates!!

# Middle of LCT coding region: 136570316
# Middle of COL4A3 coding region: 228103014

# cd /rchrist/data/1kgenomes
# /opt/bcftools/bin/bcftools view --regions 2:136608646-136608646 --types snps --min-ac 2:minor -Ou --threads 32 ALLchr2phase3_shapeit2_mvncall_integrated_v5a20130502genotypes.vcf.gz | /opt/bcftools/bin/bcftools convert -h lct --threads 32
# /opt/bcftools/bin/bcftools view --regions 2:227103014-229103014 --types snps --min-ac 2:minor -Ou --threads 32 ALLchr2phase3_shapeit2_mvncall_integrated_v5a20130502genotypes.vcf.gz | /opt/bcftools/bin/bcftools convert -h col4a3 --threads 32
# /opt/bcftools/bin/bcftools view --regions 1:158174683-160174683 --types snps --min-ac 2:minor -Ou --threads 32 ALL.chr1.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz | /opt/bcftools/bin/bcftools convert -h ackr1 --threads 32
#
# gunzip lct.legend.gz
# gunzip col4a3.legend.gz
# cp ackr1.legend.gz copy_ackr1.legend.gz
# gunzip ackr1.legend.gz
# mv copy_ackr1.legend.gz ackr1.legend.gz



# Declare gene name and other run parameters (eg: directories)
#################################################################

chr <- 2L
gene <- "lct"
gene_target_pos <- 136608646
# this is rs4988235, the "european" 13910 C>T polymorphism causing lactase persistence
# Howevever, as in the Busby et al. analysis, the C-T variant does not appear to track with any of
# our haplotype blocks.

# chr <- 2L
# gene <- "col4a3"
# gene_target_pos <- 228103014


# chr <- 1L
# gene <- "ackr1"
# gene_target_pos <- 159174683


cluster_by <- "isAFR"
#cluster_by <- "reg"
#cluster_by <- "pop"

nthreads <- 32L
data_dir <- "/rchrist/data/1kgenomes/"
recomb_map_dir <- "/rchrist/data/recomb_maps/hg19/"

#neg_log10_Ne <- 2
neg_log10_Ne <- 10 #8
neg_log10_mu <- 4 #4


# Set up helper functions and libraries
#########################################################

plot_mat <- function(x,file,raster=TRUE,rel_scale = TRUE){

  temp_col_scale <- rev(viridisLite::viridis(100))

  if(!rel_scale){
    mx <- ceiling(max(x,na.rm = T))
    if(mx > 100){stop("the max entry of x cannot exceed 100 for this plot's color scale")}
    temp_col_scale <- temp_col_scale[1:mx]
  }

  cairo_pdf(file)
  print(lattice::levelplot(x[,ncol(x):1],
                           useRaster = raster,
                           col.regions =   grDevices::colorRampPalette(#
                             temp_col_scale,
                             bias = 1 # <1 bias means more dark colors, >1 bias means more light colors
                           )(100),
                           yaxt = "n", xaxt = "n", xlab = "", ylab = "", xaxt = "n"))
  dev.off()
}

interp_hapmap <- function(path,bp){
  d <- data.table::fread(path)
  approx(d$`Position(bp)`,d$`Map(cM)`,xout = bp,method = "linear",rule=2)$y
}

dip2hapidx <- function(x){
  x <- 2*x
  c(rbind(x-1, x))
}



require(kalis)
require(data.table)
require(fastcluster)
require(Matrix)
install.packages("kgp")
library(kgp)
data(kgp)




# Load legend & samples and merge samples with 1kgenomes pop data
######################################################################
legend <- fread(paste0(data_dir,gene,".legend"))
id <- fread(paste0(data_dir,gene,".samples"))$sample
pos <- legend$position


initial_n_samples <- length(id)

all.equal(id,kgp3$id)

init_order_samples <- order(id)
samples <- merge(data.table("id" = id),kgp3,by="id")
if(nrow(samples)!= initial_n_samples){stop("some samples have been removed by merging with kgp3")}
if(!all.equal(init_order_samples,order(samples$id))){stop("some samples have been moved out of the order in lct.samples")}

samples[,isAFR:= ifelse(reg=="AFR","AFR","not_AFR")]

# ID target locus
######################

target_idx <- match(TRUE,pos>=gene_target_pos)
# just checked that these SNPs line up with gnomAD variants
# in hg19 on the UCSC browser
legend[seq(target_idx-10,target_idx+10),]


# Build weighted recombination map using samples
#####################################################

w <- table(samples$pop)
pops <- names(w)

p <- paste0(recomb_map_dir,pops,"/",pops,"_recombination_map_hapmap_format_hg19_chr_",chr,".txt")

diff_map <- rep(0,length(pos)-1L)
for(i in 1:length(pops)){
  diff_map <- diff_map + diff(interp_hapmap(p[i],pos)) * w[i]
  print(i)
}
diff_map <- diff_map / sum(w)




# Obtain DistMat at LCT
#####################################

CacheHaplotypes(haps = paste0(data_dir,gene,".hap.gz"))

G <- as(QueryCache(),"dgCMatrix")

af <- rowMeans(G)
G <- (G - af) / sqrt(N()*af*(1-af))
R <- crossprod(G)

pars <- Parameters(rho = CalcRho(diff_map,s = 10^-neg_log10_Ne), mu = 10^-neg_log10_mu)
fwd <- MakeForwardTable(pars)
bck <- MakeBackwardTable(pars)

Forward(fwd,pars,target_idx,nthreads = nthreads)
Backward(bck,pars,target_idx,nthreads = nthreads)

M <- DistMat(fwd,bck,type = "raw",nthreads = nthreads)

# tM <- M
# mc <- max.col(tM)
# md <- tM[cbind(1:N(),mc)]
# #rounded_md <- ceiling(md*1e3)/1e3
# rounded_md <- round(md)
# tM <- tM + (rounded_md - md)


M <- (0.5/(neg_log10_mu*log(10))) * (M + t(M))
# Permute & Cluster Distance Matrix to Display Pops within Regions
###################################################################

diploid_perm <- order(samples$reg,samples$pop,samples$id)
psamples <- samples[diploid_perm,]

# let's check psamples using rle
rle_pop <- rle(psamples$pop)
if(length(rle_pop$values) != length(pops)){
  stop("the rows of psamples are not sorted by population")}


haploid_perm <- dip2hapidx(diploid_perm)

pR <- R[,haploid_perm][haploid_perm,]
pM <- M[,haploid_perm][haploid_perm,]


hap_groups <- table(psamples[[cluster_by]])
# make sure groups are ordered in the same order they appear in psamples
hap_groups <- hap_groups[unique(psamples[[cluster_by]])]

baseline_idx <- c(0,cumsum(2*hap_groups)[-length(hap_groups)])
names(baseline_idx) <- names(hap_groups)

order_M <- as.list(hap_groups)
names(order_M) <- names(hap_groups)

for(i in 1:length(hap_groups)){
  current_pop_samples <- which(psamples[[cluster_by]]==names(hap_groups)[i])
  current_pop_haplotypes <- dip2hapidx(current_pop_samples)
  sM <- pM[current_pop_haplotypes,current_pop_haplotypes]
  order_M[[names(hap_groups)[i]]] <- baseline_idx[names(hap_groups)[i]] + fastcluster::hclust(as.dist(sM),method="average")$order
}

order_M <- unlist(order_M)


if(!all.equal(sort(unname(order_M)),1:N())){
  stop("order_M does not set equal 1:N()")}

cM <- pM[,order_M][order_M,]

cpop <- rep(psamples$pop,each=2)[order_M]
creg <- rep(psamples$reg,each=2)[order_M]

ctarget_var <- c(QueryCache(loci.idx =  which(legend$position == gene_target_pos)))[order_M]

# Make plots
#######################

#qsubset <- dip2hapidx(c(which(psamples$pop=="GBR"),which(psamples$pop=="YRI"),which(psamples$pop=="CHB")))
#plot_mat(cM[,qsubset][qsubset,],paste0(data_dir,gene,"_GBR_YRI_CHB_dist_mat.pdf"))

#qsubset <- dip2hapidx(which(psamples$isAFR=="AFR"))
#plot_mat(cM[,qsubset][qsubset,],paste0(data_dir,gene,"_AFR_dist_mat.pdf"))

# system.time({
# qsubset <- dip2hapidx(which(psamples$isAFR=="AFR"))
# plot_mat(cM[,qsubset][qsubset,],paste0(data_dir,gene,"_AFR_dist_raster_mat.pdf"))
# })

start <- proc.time()
plot_mat(cM,paste0(data_dir,gene,"_dist_mat.pdf"))
finish <- proc.time() - start
