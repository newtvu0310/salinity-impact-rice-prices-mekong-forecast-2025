/* ================================================================
   DỰ BÁO GIÁ GẠO ĐBSCL – SARIMAX(2,1,2)-ARCH(1)
   Tác giả : Trương Minh Đạt, Vũ Thái Tân, Nguyễn Minh Khương,
             Nguyễn Hoàng Nga, Nguyễn Đào Kim Ngân
   Trường  : UEH – Khoa Kinh tế, Luật và Quản lý Nhà nước
   ================================================================ */

clear all
set more off
set linesize 120

* ── Tạo thư mục lưu đồ thị ──────────────────────────────────
capture mkdir "graphs"

* ── Palette màu nhất quán (GitHub-friendly) ──────────────────
global C1  "navy"          // Giá thực tế
global C2  "cranberry"     // Giá dự báo  
global C3  "forest_green"  // Tập train / tham chiếu
global C4  "dkorange"      // Nhấn mạnh

* ── Tuỳ chọn đồ thị chung ────────────────────────────────────
global GBASE graphregion(color(white) fcolor(white))         ///
              plotregion(color(white)  fcolor(white))

global GFONT title(, size(medlarge) color(black))            ///
              subtitle(, size(small)   color(gs6))            ///
              note(, size(vsmall) color(gs8))                 ///
              xtitle(, size(small)) ytitle(, size(small))     ///
              xlabel(, labsize(vsmall)) ylabel(, labsize(vsmall))

global EXPORT width(2400) height(1400)   // PNG export size


/* ================================================================
   1. NẠP & ĐỊNH DẠNG DỮ LIỆU
   ================================================================ */
import excel "C:\Users\Admin\Desktop\ECON PREDICT\TieuLuanCuoiKy_TruongMinhDat_VuThaiTan_NguyenMinhKhuong_NguyenHoangNga_NguyenDaoKimNgan\DU_LIEU_CHAY_DU_BAO.xlsx", sheet("Sheet1") firstrow case(lower)

* Phân tách chuỗi thời gian "W2-Jan-23" → tuần / tháng / năm
gen weeknum  = real(substr(week_month, 2, 1))
gen monthstr = substr(week_month, 4, 3)
gen year     = real(substr(week_month, 8, 2)) + 2000

gen month = .
replace month =  1 if monthstr == "jan"
replace month =  2 if monthstr == "feb"
replace month =  3 if monthstr == "mar"
replace month =  4 if monthstr == "apr"
replace month =  5 if monthstr == "may"
replace month =  6 if monthstr == "jun"
replace month =  7 if monthstr == "jul"
replace month =  8 if monthstr == "aug"
replace month =  9 if monthstr == "sep"
replace month = 10 if monthstr == "oct"
replace month = 11 if monthstr == "nov"
replace month = 12 if monthstr == "dec"

gen day     = 1 + (weeknum - 1) * 7
gen date    = mdy(month, day, year)
format date %td

gen week_ts = wofd(date)
format week_ts %tw
tsset week_ts

drop if missing(week_ts)
capture drop h i j k       // loại cột rác nếu có (bỏ qua nếu không tồn tại)


/* ================================================================
   2. BIẾN PHỤ TRỢ
   ================================================================ */
* Biến điều hoà mùa vụ (52 tuần/năm)
gen week_num = _n
gen sin52    = sin(2 * _pi * week_num / 52)
gen cos52    = cos(2 * _pi * week_num / 52)

* Biến sai phân – kiểm định tính dừng
gen d_price = d.giágạohạtdài

* Biến huấn luyện (để trống 12 quan sát cuối → tập dự báo)
gen price = giágạohạtdài
forvalues i = 129/140 {
    replace price = . in `i'
}


/* ================================================================
   3. KIỂM ĐỊNH TÍNH DỪNG (ADF)
   ================================================================ */
di _n "{hline 55}"
di "   BẢNG 3 – Kiểm định Augmented Dickey-Fuller"
di "{hline 55}"

foreach v of varlist giágạohạtdài lượngmưa                 ///
                     diệntíchgieotrồngha năngsuấtlúatạha   ///
                     sảnlượnglúatấnha tb price {
    quietly dfuller `v'
    di "  `v' : t = " %7.3f r(Zt) "   p = " %5.4f r(p)
}

di _n "  Sai phân bậc 1:"
foreach v of varlist giágạohạtdài price {
    quietly dfuller d.`v'
    di "  d.`v' : t = " %7.3f r(Zt) "   p = " %5.4f r(p)
}


/* ================================================================
   GRAPH 1 – Chuỗi giá gạo gốc
   ================================================================ */
tsline giágạohạtdài,                                            ///
    lcolor($C1) lwidth(medthin)                                 ///
    title("Giá Gạo Hạt Dài – Thị trường Nội địa ĐBSCL",       ///
          size(medlarge) color(black))                          ///
    subtitle("Tháng 5/2022 – Tháng 3/2025", size(small) color(gs6)) ///
    ytitle("VNĐ/kg", size(small))                               ///
    xtitle("Tuần", size(small))                                 ///
    note("Nguồn: Hiệp hội Lương thực Việt Nam (VFA)", size(vsmall)) ///
    legend(off) $GBASE $GFONT
graph export "graphs/01_rice_price_series.png", replace $EXPORT


/* ================================================================
   GRAPH 2 – ACF & PACF của sai phân giá gạo
   ================================================================ */
ac d_price, lag(20) name(ACF, replace)                         ///
    title("ACF – Sai phân Giá Gạo", size(medium) color(black)) ///
    subtitle("Xác định bậc MA (q)", size(small) color(gs6))    ///
    ytitle("Tự tương quan", size(small))                        ///
    xtitle("Độ trễ (tuần)", size(small))                        ///
    $GBASE $GFONT

pac d_price, lag(20) name(PACF, replace)                       ///
    title("PACF – Sai phân Giá Gạo", size(medium) color(black)) ///
    subtitle("Xác định bậc AR (p)", size(small) color(gs6))    ///
    ytitle("Tự tương quan riêng phần", size(small))             ///
    xtitle("Độ trễ (tuần)", size(small))                        ///
    $GBASE $GFONT

graph combine ACF PACF, cols(2)                                 ///
    title("Phân tích Tự tương quan (ACF & PACF)",               ///
          size(medlarge) color(black))                          ///
    note("Sai phân bậc 1 chuỗi giá gạo hạt dài · Khoảng tin cậy 95%", ///
         size(vsmall) color(gs8))                               ///
    $GBASE xsize(10) ysize(5)
graph export "graphs/02_acf_pacf_diff.png", replace width(2400) height(1200)


/* ================================================================
   4. SO SÁNH MÔ HÌNH SARIMAX
   ================================================================ */
local xvars "tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52"

arima price `xvars', arima(0,1,2)
estimates store M012
estat ic
matrix IC = r(S)
local AIC012 = IC[1,5]
local BIC012 = IC[1,6]
local LL012  = IC[1,3]

arima price `xvars', arima(1,1,2)
estimates store M112
estat ic
matrix IC = r(S)
local AIC112 = IC[1,5]
local BIC112 = IC[1,6]
local LL112  = IC[1,3]

arima price `xvars', arima(2,1,2)
estimates store M212
estat ic
matrix IC = r(S)
local AIC212 = IC[1,5]
local BIC212 = IC[1,6]
local LL212  = IC[1,3]

di _n "{hline 60}"
di "   BẢNG 5 – So sánh mô hình SARIMAX"
di "{hline 60}"
di "  Mô hình          LogL          AIC           BIC"
di "  ARIMA(0,1,2)   " %10.4f `LL012'  "   " %10.4f `AIC012'  "   " %10.4f `BIC012'
di "  ARIMA(1,1,2)   " %10.4f `LL112'  "   " %10.4f `AIC112'  "   " %10.4f `BIC112'
di "  ARIMA(2,1,2)   " %10.4f `LL212'  "   " %10.4f `AIC212'  "   " %10.4f `BIC212'
di "{hline 60}"

esttab M012 M112 M212,                                          ///
    nogap br                                                    ///
    mtitles("ARIMA(0,1,2)" "ARIMA(1,1,2)" "ARIMA(2,1,2)")     ///
    scalar(ll aic bic) sfmt(4)                                  ///
    star(* 0.1 ** 0.05 *** 0.01)                                ///
    title("So sánh mô hình SARIMAX")


/* ================================================================
   5. CHẨN ĐOÁN PHẦN DƯ – SARIMAX(1,1,2)
   ================================================================ */
arima price `xvars', arima(1,1,2)
predict res_sax, residuals
gen     res2_sax = res_sax ^ 2


/* ── GRAPH 3a : Phần dư theo thời gian ──────────────────── */
tsline res_sax,                                                 ///
    lcolor($C1) lwidth(thin)                                    ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin))           ///
    title("Phần dư – SARIMAX(1,1,2)", size(medium) color(black)) ///
    subtitle("Kiểm tra giả định đồng nhất phương sai",          ///
             size(small) color(gs6))                            ///
    ytitle("Phần dư", size(small)) xtitle("Tuần", size(small)) ///
    $GBASE $GFONT name(RES, replace)


/* ── GRAPH 3b : Phần dư bình phương ─────────────────────── */
tsline res2_sax,                                                ///
    lcolor($C2) lwidth(thin)                                    ///
    title("Phần dư Bình phương – Volatility Clustering",        ///
          size(medium) color(black))                            ///
    subtitle("Dấu hiệu hiệu ứng ARCH", size(small) color(gs6)) ///
    ytitle("Phần dư²", size(small)) xtitle("Tuần", size(small)) ///
    $GBASE $GFONT name(RES2, replace)

graph combine RES RES2, cols(1) xsize(10) ysize(8)             ///
    title("Chẩn đoán Phần dư – SARIMAX(1,1,2)",                ///
          size(medlarge) color(black))                          ///
    $GBASE
graph export "graphs/03_residual_diagnostics.png", replace width(2400) height(2000)


/* ── GRAPH 4 : ACF & PACF phần dư bình phương ───────────── */
ac  res2_sax, lag(20) name(ACF2, replace)                       ///
    title("ACF – Phần dư²", size(medium) color(black))          ///
    subtitle("Kiểm tra tự tương quan phương sai",               ///
             size(small) color(gs6))                            ///
    ytitle("Tự tương quan", size(small))                        ///
    xtitle("Độ trễ", size(small))                               ///
    $GBASE $GFONT

pac res2_sax, lag(20) name(PACF2, replace)                      ///
    title("PACF – Phần dư²", size(medium) color(black))         ///
    subtitle("Xác định bậc ARCH", size(small) color(gs6))       ///
    ytitle("Tự tương quan riêng phần", size(small))             ///
    xtitle("Độ trễ", size(small))                               ///
    $GBASE $GFONT

graph combine ACF2 PACF2, cols(2) xsize(10) ysize(5)           ///
    title("ACF & PACF của Phần dư Bình phương",                 ///
          size(medlarge) color(black))                          ///
    note("Cơ sở lựa chọn bậc ARCH · Khoảng tin cậy 95%",       ///
         size(vsmall) color(gs8))                               ///
    $GBASE
graph export "graphs/04_acf_pacf_residuals2.png", replace width(2400) height(1200)


/* ── Kiểm định ARCH-LM ───────────────────────────────────── */
di _n "{hline 50}"
di "   BẢNG 6 – Kiểm định ARCH-LM"
di "{hline 50}"
* estat archlm yêu cầu chạy regress trước (không dùng được ngay sau arima/graph)
quietly regress res2_sax L.res2_sax
estat archlm, lags(1)


/* ================================================================
   6. MÔ HÌNH SARIMAX-ARCH – SO SÁNH VÀ LỰA CHỌN
   ================================================================ */
foreach spec in "0,1,2" "1,1,2" "2,1,2" {
    arch price `xvars', arch(1/1) arima(`spec')
    local tag = subinstr("`spec'", ",", "", .)
    estimates store A`tag'
    estat ic
}

esttab A012 A112 A212,                                          ///
    nogap br                                                    ///
    mtitles("SAX-AR(0,1,2)" "SAX-AR(1,1,2)" "SAX-AR(2,1,2)") ///
    scalar(ll aic bic) sfmt(4)                                  ///
    star(* 0.1 ** 0.05 *** 0.01)                                ///
    title("So sánh SARIMAX-ARCH (Bảng 7)")


/* ================================================================
   7. MÔ HÌNH TỐI ƯU: SARIMAX(2,1,2)-ARCH(1)
   ================================================================ */
arch price `xvars', arch(1/1) arima(2,1,2)

di _n "{hline 55}"
di "   BẢNG 8-9 – Kết quả hồi quy SARIMAX(2,1,2)-ARCH(1)"
di "{hline 55}"

predict res_final,  residuals
predict yhat_final, xb
gen giá_gạo_dự_báo = L.giágạohạtdài + yhat_final if _n > 1


/* ── GRAPH 5 : Q-Q Plot & Histogram phần dư ─────────────── */
qnorm res_final,                                                ///
    mcolor($C1%70) msize(vsmall) msymbol(circle)               ///
    title("Q-Q Plot – Phần dư SARIMAX(2,1,2)-ARCH(1)",         ///
          size(medium) color(black))                            ///
    subtitle("Kiểm tra phân phối chuẩn", size(small) color(gs6)) ///
    xtitle("Quantile lý thuyết", size(small))                   ///
    ytitle("Quantile mẫu", size(small))                         ///
    $GBASE $GFONT name(QQ, replace)

histogram res_final, normal bin(25)                             ///
    fcolor($C1%40) lcolor($C1) lwidth(thin)                    ///
    title("Phân phối Phần dư", size(medium) color(black))       ///
    subtitle("So sánh với đường chuẩn", size(small) color(gs6)) ///
    xtitle("Phần dư", size(small))                              ///
    ytitle("Mật độ", size(small))                               ///
    $GBASE $GFONT name(HIST, replace)

graph combine QQ HIST, cols(2) xsize(10) ysize(5)              ///
    title("Chẩn đoán Phân phối Phần dư – Mô hình cuối",        ///
          size(medlarge) color(black))                          ///
    $GBASE
graph export "graphs/05_final_residual_distribution.png", replace width(2400) height(1200)


/* ── GRAPH 6 : Scatter phần dư theo thời gian ───────────── */
scatter res_final week_ts,                                      ///
    mcolor($C1%50) msize(vsmall) msymbol(circle)               ///
    yline(0, lcolor($C2) lpattern(dash) lwidth(thin))           ///
    title("Phần dư Theo Thời gian – SARIMAX(2,1,2)-ARCH(1)",   ///
          size(medium) color(black))                            ///
    subtitle("Kiểm tra tính ngẫu nhiên của sai số",             ///
             size(small) color(gs6))                            ///
    ytitle("Phần dư", size(small))                              ///
    xtitle("Tuần", size(small))                                 ///
    note("White noise test: Q = 28.51  |  Prob > χ²(40) = 0.9125", ///
         size(vsmall) color(gs8))                               ///
    $GBASE $GFONT
graph export "graphs/06_residuals_scatter.png", replace width(2400) height(1300)


/* ── GRAPH 7 : Dự báo vs. Thực tế ──────────────────────── */
twoway                                                          ///
    (tsline giágạohạtdài,                                      ///
        lcolor($C1) lwidth(medthin) lpattern(solid))           ///
    (tsline giá_gạo_dự_báo,                                    ///
        lcolor($C2) lwidth(medthin) lpattern(solid))           ///
    (tsline price,                                              ///
        lcolor($C3) lwidth(medthick) lpattern(dash)),      ///
    title("Dự báo Giá Gạo Hạt Dài – SARIMAX(2,1,2)-ARCH(1)", ///
          size(medlarge) color(black))                          ///
    subtitle("Tháng 1/2025 – Tháng 3/2025", size(small) color(gs6)) ///
    ytitle("VNĐ/kg", size(small))                               ///
    xtitle("Tuần", size(small))                                 ///
    legend(order(1 "Giá thực tế" 2 "Giá dự báo" 3 "Tập huấn luyện") ///
           rows(1) position(6) size(small)                      ///
           region(lcolor(gs12)) symxsize(small))                ///
    note("Nguồn: VFA · Mô hình tối ưu: AIC = 1632.58 | BIC = 1671.25 | MAPE = 2.51%", ///
         size(vsmall) color(gs8))                               ///
    $GBASE $GFONT
graph export "graphs/07_forecast_vs_actual.png", replace $EXPORT


/* ================================================================
   8. CHỈ SỐ ĐÁNH GIÁ MÔ HÌNH
   ================================================================ */
gen error_e    = price - giá_gạo_dự_báo
gen abs_error  = abs(error_e)
gen sq_error   = error_e ^ 2
gen ape        = abs(error_e / price)

quietly summarize abs_error
local MAE  = r(mean)
quietly summarize sq_error
local RMSE = sqrt(r(mean))
quietly summarize ape
local MAPE = r(mean) * 100

di _n "{hline 50}"
di "   BẢNG 10 – Đánh giá mô hình SARIMAX(2,1,2)-ARCH(1)"
di "{hline 50}"
di "  MAE  = " %8.4f `MAE'  " VNĐ/kg"
di "  RMSE = " %8.4f `RMSE' " VNĐ/kg"
di "  MAPE = " %6.2f `MAPE' "%"
di "{hline 50}"


/* ── GRAPH 8 : Sai số tuyệt đối theo thời gian ──────────── */
gen has_error = !missing(abs_error)
twoway                                                          ///
    (bar abs_error week_ts if has_error,                        ///
        barwidth(0.3) fcolor($C4%50) lcolor($C4) lwidth(vthin)), ///
    title("Sai số Tuyệt đối – SARIMAX(2,1,2)-ARCH(1)",         ///
          size(medium) color(black))                            ///
    subtitle("Tập dự báo tháng 1–3/2025", size(small) color(gs6)) ///
    ytitle("|Giá thực – Giá dự báo| (VNĐ/kg)", size(small))    ///
    xtitle("Tuần", size(small))                                 ///
    note("MAE = " + string(`MAE', "%6.2f") + " | RMSE = " +    ///
         string(`RMSE', "%6.2f") + " | MAPE = " +              ///
         string(`MAPE', "%4.2f") + "%",                         ///
         size(vsmall) color(gs8))                               ///
    $GBASE $GFONT
graph export "graphs/08_absolute_errors.png", replace $EXPORT


di _n "✅ Xong! Tất cả đồ thị đã được lưu vào thư mục  graphs/"
di "   01_rice_price_series.png"
di "   02_acf_pacf_diff.png"
di "   03_residual_diagnostics.png"
di "   04_acf_pacf_residuals2.png"
di "   05_final_residual_distribution.png"
di "   06_residuals_scatter.png"
di "   07_forecast_vs_actual.png"
di "   08_absolute_errors.png"
