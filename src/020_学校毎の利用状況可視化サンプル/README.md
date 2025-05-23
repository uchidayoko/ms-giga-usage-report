<a name="top"></a>

# Microsoft 365 学校毎の利用状況可視化サンプル利用ガイド
Microsoft 365 学校毎の利用状況可視化サンプルのPBITファイルのセットアップと利用方法を解説します。

## 目次

- [対象者](#-対象者)
- [概要](#-概要)
- [前提条件](#-前提条件)
- [事前準備](#-事前準備)
- [利用手順](#-利用手順)
- [M365名簿の更新方法](#-M365名簿の更新方法)
- [注意事項](#-注意事項)
- [関連情報](#-関連情報)

## 👨‍💻👩‍💻 対象者

本ガイドは、Microsoft 365 学校毎の利用状況可視化サンプルを閲覧するユーザーが対象です。  
Microsoft 365 学校毎の利用状況可視化サンプルでは、データ収集の対象となるユーザーの所属やIDなどの情報を匿名化せずに利用します。  
そのため、システム全体の管理者など、テナント全所属者に関する情報の閲覧権限を持ったユーザーのみの利用を推奨します。

## 💻 概要

学校毎のMicrosoft 365 の利用状況を可視化します。  
利用日数に応じて区分された利用人数および利用率を、学校毎に集計します。

**【システム構成図】**
```mermaid
graph BT
    subgraph Microsoft365 ["<div style='font-size:24px;'><b>Microsoft 365</b></div>"]
        usageReport["<div style='text-align: left;'><b>利用状況レポート</b><br>日毎のMicrosoft 365 の<br>利用結果データ</div>"]
        style usageReport fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656

        usageReportSetting["<div style='text-align: left;'><b>利用状況レポートの<br>匿名化設定</b></div>"]
        style usageReportSetting fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656

        UserData["<div style='text-align: left;'><b>Entra ID ユーザー情報</b></div>"]
        style UserData fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656

        subgraph SharePoint ["<b>SharePoint Online</b>"]
            subgraph SharePointSite ["<b>M365UsageRecords サイト</b>"]
                roster[("<div style='text-align: left;'><b>M365名簿(Roster)</b><br>ユーザーの所属情報<br>を記載したExcelファイル</div>")]
                style roster fill:#F6F8FA,stroke:#565656,stroke-width:1px,stroke-dasharray:5,color:#565656

                usageRecords[("<div style='text-align: left;'><b>M365UsageRecords</b><br>利用状況レポートのデータ<br>等を記載したCSVファイル</div>")]
                style usageRecords fill:#F6F8FA,stroke:#565656,stroke-width:1px,stroke-dasharray:5,color:#565656
            end
            style SharePointSite fill:#F6F8FA,stroke:#565656,stroke-width:2px,color:#565656
        end
        style SharePoint fill:#14858d,stroke:#565656,stroke-width:2px,color:#fff

        subgraph PowerBIService ["<b><br>Power BI サービス</b>"]
            powerBIReport["<div style='text-align: left;'><b>Power BI レポート</b><br>レポートを表示し<br>データを自動更新</div>"]
            style powerBIReport fill:#F6F8FA,stroke:#565656,stroke-width:1px,color:#565656
        end
        style PowerBIService fill:#e8b41b,stroke:#565656,stroke-width:2px,color:#fff

    end
    style Microsoft365 fill:#E5F1FB,stroke:#565656,stroke-width:2px,color:#565656

    subgraph GitHub ["<div style='font-size:24px;'><b>GitHub</b></div>"]
        subgraph githubRepo ["<b>GitHub リポジトリ</b>"]
            githubActions["<div style='text-align: left;'><b>GitHub Actions</b><br>・利用状況レポート等の<br>　データ取得<br>・SharePoint Online サイト<br>　へのデータ自動保存</div>"]
            style githubActions fill:#F6F8FA,stroke:#565656,stroke-width:1px,stroke-dasharray:5,color:#565656
        end
        style githubRepo fill:#F6F8FA,stroke:#565656,stroke-width:2px,color:#565656
    end
    style GitHub fill:#848F9C,stroke:#565656,stroke-width:2px,color:#fff

    user["<div style='text-align: left;'><b>レポート利用者</b><br>Power BI レポートを利用</div>"]
    style user fill:#565656,stroke:#565656,stroke-width:2px,color:#fff

    powerBIReport -->|データを参照| SharePointSite
    GitHub -->|データを取得| usageReport
    GitHub -->|データを取得| usageReportSetting
    GitHub -->|データを取得| UserData
    GitHub -->|データを保存| usageRecords
    user -->|作成と<br>アップロード| roster
    user -->|レポートを閲覧| powerBIReport
    linkStyle 0 stroke:#565656, stroke-width:1.5px;
    linkStyle 1 stroke:#565656, stroke-width:1.5px;
    linkStyle 2 stroke:#565656, stroke-width:1.5px;
    linkStyle 3 stroke:#565656, stroke-width:1.5px;
    linkStyle 4 stroke:#565656, stroke-width:1.5px;
    linkStyle 5 stroke:#565656, stroke-width:1.5px;
    linkStyle 6 stroke:#565656, stroke-width:1.5px;
```

**【レポート画面】**

|<img src="images/Report_020_Explanation.png" width="600">|
|---------|

画像の番号ごとにレポートの概要を説明します。

| 番号 | 概要 |
|---------|---------|
| ① | 集計対象の年度を選択します。複数選択も可能です。 |
| ② | 集計対象の学校を選択します。複数選択も可能です。 |
| ③ | 集計対象の利用者区分を選択します。複数選択も可能です。 |
| ④ | 集計対象のデータ期間を表します。 |
| ⑤ | 集計期間において、利用頻度ごとに利用人数を集計します。 |
| ⑥ | 利用頻度毎の利用人数を月別に表示します。 |
| ⑦ | 利用頻度毎の利用人数を機能（アプリ）別に表示します。 |
| ⑧ | 利用頻度毎の利用人数を学校別に表示します。<br>「+」をクリックすると 役割＞学級＞週 の粒度に分解できます。 |
| ⑨ | 表示しているデータについて、補足や留意事項を記載しています。 |

集計に利用している利用頻度は以下のように定義しています。
| 利用頻度 | 説明 |
|---------|---------|
| 週 5 日以上 | 集計期間の日数のうち、5/7 以上利用している |
| 週 3 日以上 | 集計期間の日数のうち、3/7 以上・5/7 未満利用している |
| 週 1 日以上 | 集計期間の日数のうち、1/7 以上・3/7 未満利用している |
| 月 1 日以上 | 集計期間の日数のうち、12/365 以上・1/7 未満利用している |
| 月 1 日未満 | 集計期間の日数のうち、12/365 未満利用している、または利用していない<br>※利用していない人数は、M365名簿に登録されているアカウントのうち、利用ログが0件であるアカウント数を指します。 |

> [!NOTE]
> + 新入生および卒業生は、在籍期間を対象として利用頻度が集計されます。
> + 各ユーザーの所属情報は、年度毎の最新のM365名簿に記載されている情報を利用しています。
> + 利用人数の総数は、年度毎の最新のM365名簿に記載されているユーザー数から算出しています。
> + M365名簿についての詳細は、[1. M365名簿の作成](#1-M365名簿の作成)をご確認ください。
## ✅ 前提条件

Microsoft 365 学校毎の利用状況可視化サンプルを使用するには以下の前提条件を満たす必要があります。

1. **環境構築**  
   テナントのシステム管理者によって、 [環境構築手順](/README.md#-%E7%92%B0%E5%A2%83%E6%A7%8B%E7%AF%89%E6%89%8B%E9%A0%86) が完了していることを確認してください。

1. **Microsoft 365 アカウント**  
   Power BI Desktop や Power BI サービスにサインインするための有効な Microsoft 365 アカウントが必要です。

2. **Microsoft 365 A1ライセンス**  
   本プロジェクトのレポートを活用するためには、最低でもMicrosoft 365 A1ライセンスが必要です。  

3. **インターネット接続**  
   Power BI Desktop からデータソースとなる  Online へのアクセスやPower BI サービスのアクセスにインターネット接続が必須です。

4. **Power BI Desktop のインストール**  
   PCに Power BI Desktop がインストールされていることを確認してください。  
   詳細は[こちら（Power BI Desktop の取得 - Power BI | Microsoft Learn）<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/fundamentals/desktop-get-the-desktop) の手順に従ってください。  

> [!IMPORTANT]
> + インストールのための [最小要件（Power BI Desktop の取得 - Power BI | Microsoft Learn）<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/fundamentals/desktop-get-the-desktop#minimum-requirements) を確認してください。
> + 端末のメモリ (RAM) が 4 GB 以下だと動作しない可能性があります。

> [!NOTE]
> + Power BI Desktop のインストールにはPCの管理者権限が必要になる場合があります。
> + Power BI Desktop の起動後、「WebView2に問題があります」と表示された場合は以下のMicrosoft Learnを参考にしてください。
>   [Power BI Desktop の起動に関する問題を解決する - Power BI | Microsoft Learn<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/connect-data/desktop-error-launching-desktop)

6. **データソースへのアクセス権**  
   SharePoint Online サイト上のデータソースへのアクセス権限を持っていることを確認してください。

> [!NOTE]
> + データソースとなるサイトのURLは、[環境構築手順　9. 動作確認](/README.md#9-%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D) に記載されています。
> + アクセス権限が無い場合は [データソースへのアクセス権設定](/README.md#-%E3%83%87%E3%83%BC%E3%82%BF%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%B8%E3%81%AE%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E6%A8%A9%E8%A8%AD%E5%AE%9A) を実施してください。

## 📥 事前準備

### 1. M365名簿の作成
**M365名簿**とは、各ユーザーのIDや所属情報を含む名簿ファイルのことです。  
端末の利用状況を学校毎に可視化するためには、M365名簿の作成が必要になります。  
以下に記載の手順で作成してください。

<details>
<summary>　クリックして詳細表示</summary>

> 1. [サンプルファイル<img src="images/link-external.svg">](https://github.com/uchidayoko/ms-giga-usage-report/blob/main/src/020_%E5%AD%A6%E6%A0%A1%E6%AF%8E%E3%81%AE%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E5%8F%AF%E8%A6%96%E5%8C%96%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/%E5%90%8D%E7%B0%BF%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/2024-04-01_M365%E5%90%8D%E7%B0%BF.xlsx) をダウンロードします。
> 
> |<img src="images/Create_Roster_1.jpg" width="600">|
> |---------|
> 
> 2. 名簿作成時の日付でファイル名を「yyyy-mm-dd_M365名簿.xlsx」に変更します。
>
>      - yyyy-mm-ddにM365名簿を作成した日付を入力します。  
>       例：2025年4月1日にファイルを作成した場合、ファイル名は「2025-04-01_M365名簿.xlsx」となります。
> 
> |<img src="images/Create_Roster_2.jpg" width="600">|
> |---------|
>
>  3. ファイルに以下の項目を入力します。
>
>      - 記載されているサンプルデータは削除してください。
> 
> | 列名 | 格納されるデータの内容 | 例 | 備考 |
> |---|---|---|---|
> | **年度** | 名簿の対象となる年度<br>数字4桁 | 2025　など |  |
> | **所属名** | 対象者の所属 | ダミー小学校<br>教育委員会　など |  |
> | **M365ID** | 対象者のMicrosoft 365 ID | aaaaa@bbb.onmicrosoft.com<br>xxx@yyy.ed.jp　など | 同一年度内で重複が無いようにしてください。<br>兼任者の場合はどちらか一方を記載してください。 |
> | **氏名** | 対象者の氏名 | 内田　洋子<br>youko-uchida　など | 現在はレポートに表示していないため、空欄でも構いません。 |
> | **役割** | 対象者の役割・肩書 | 児童生徒<br>教員<br>全体管理者　のいずれか |  |
> | **学級名** | 対象者の所属する学級名 | 1年1組<br>ひまわり学級 など | 相当するものがなければ空欄でも構いません。<br>運用負荷を考慮して一律「未設定」という文言も可能です。 |
> 
> |<img src="images/Create_Roster_3.jpg" width="600">|
> |---------|

</details>

> [!CAUTION]
> + 同一年度内で「M365ID」が重複している場合は、M365名簿内で上にある情報が取得されます。
> + 兼任者についてはどちらか一方を記載してください。

> [!NOTE]
> **レポートとM365名簿の関連について**  
> + レポートでは、年度毎の最新のM365名簿にある情報でデータが集計されます。
> + 各列の情報は、レポートの以下の部分に対応します。
> 
> | 列名 | レポートとの関連 |
> |---|---|
> | 年度 | 集計対象の年度とM365名簿情報を紐づけます。 |
> | 所属名 | 学校によるフィルターや学校毎の集計に利用します。 |
> | M365ID | Microsoft 365 利用データとM365名簿情報を紐づけます。 |
> | 氏名 | 現在公開中のバージョンではレポート上に表示しません。 |
> | 役割 | 役割によるフィルターや役割毎の集計に利用します。 |
> | 学級名 | 学級毎の集計に利用します。<br>空欄や任意の値を入れるとその値で表示されます。（下図参照） |
> 
> |<img src="images/Class_Name_1.jpg" width="600">|
> |---------|

### 2. M365名簿の格納場所の準備

M365名簿をSharePoint Online サイトにアップロードすることで、レポートから参照できるようにします。
アップロードするためのフォルダを作成します。

<details>
<summary>　クリックして詳細表示</summary>

> 1. データソースとなるShare Point Online サイトにアクセスします。
>
>    - サイトのURLは、[環境構築手順　9. 動作確認](/README.md#9-%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D) に記載されています。
> 
> 2. 左側のタブから、 [ドキュメント] を選択します。
> 
> |<img src="images/Create_SharePoint_Folders_1.jpg" width="600">|
> |---------|
>
> 3. [＋新規] > [フォルダー] をクリックしてフォルダーの作成画面を開きます。
> 
> |<img src="images/Create_SharePoint_Folders_2.jpg" width="600">|
> |---------|
>
> 4. 名前に「Roster」と入力して [作成] をクリックします。
>
>    - 先頭大文字の半角英字で入力してください。
> 
> |<img src="images/Create_SharePoint_Folders_3.jpg" width="600">|
> |---------|
>
> 5. 作成した「Roster」フォルダーをクリックして開きます。
> 
> |<img src="images/Create_SharePoint_Folders_4.jpg" width="600">|
> |---------|
>
> 6. [＋新規] > [フォルダー] から、「M365名簿」という名前のフォルダーを作成します。
>
>    - 「M」は大文字の半角英字、「365」は半角数字で入力してください。
> 
> |<img src="images/Create_SharePoint_Folders_5.jpg" width="600">|
> |---------|
>
> 7. 作成した「M365名簿」フォルダーをクリックして開きます。
> 8. [＋新規] > [フォルダー] から、「school_year=yyyy」という名前のフォルダーを作成します。
>
>    - 小文字の半角英字および半角記号で入力してください。
>    - 「yyyy」には登録するM365名簿の年度が入ります。  
>      2025年度分のM365名簿を登録したい場合、「school_year=2025」という名前のフォルダになります。
> 
> |<img src="images/Create_SharePoint_Folders_6.jpg" width="600">|
> |---------|
>

</details>

### 3. M365名簿のアップロード

M365名簿をSharePoint Online サイトにアップロードします。

<details>
<summary>　クリックして詳細表示</summary>

> 1. 前の手順で作成した「school_year=yyyy」フォルダーをクリックして開きます。
> 
> |<img src="images/Upload_Roster_1.jpg" width="600">|
> |---------|
>
> 2. [アップロード] > [ファイル] をクリックします。
> 
> |<img src="images/Upload_Roster_2.jpg" width="600">|
> |---------|
>
> 3. M365名簿を選択して開きます。
> 
> |<img src="images/Upload_Roster_3.jpg" width="600">|
> |---------|
>
> 4. M365名簿のパスが以下のようになっていることを確認します。
> 
>    - ドキュメント/Roster/M365名簿/school_year=yyyy/yyyy-mm-dd_M365名簿.xlsx
> 
> |<img src="images/Upload_Roster_4.jpg" width="600">|
> |---------|
>

</details>

### 2. GitHubからのPBITファイルのダウンロード

レポートを利用開始するために、以下の手順でテンプレートをダウンロードできます。

<details>
<summary>　クリックして詳細表示</summary>

> 1. [テンプレートファイル<img src="images/link-external.svg">](https://github.com/uchidayoko/ms-giga-usage-report/blob/main/src/020_%E5%AD%A6%E6%A0%A1%E6%AF%8E%E3%81%AE%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E5%8F%AF%E8%A6%96%E5%8C%96%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/02_%E5%AD%A6%E6%A0%A1%E6%AF%8E%E3%81%AE%E7%AB%AF%E6%9C%AB%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E3%83%AC%E3%83%9D%E3%83%BC%E3%83%88.pbit) をダウンロードします。
> 
> |<img src="images/Download_Template_File_1.jpg" width="600">|
> |---------|

</details>

### 3. Power BI Desktop および Power BI サービスの準備

Power BI Desktop および Power BI サービスの準備に関する手順は、  
「Microsoft 365 テナント全体の利用状況可視化サンプル利用ガイド」の [事前準備](../010_%E3%83%86%E3%83%8A%E3%83%B3%E3%83%88%E3%81%AE%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E5%8F%AF%E8%A6%96%E5%8C%96%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/README.md#-%E4%BA%8B%E5%89%8D%E6%BA%96%E5%82%99) の 手順2～4 をご確認ください。

## 📝 利用手順

レポート利用開始や閲覧、日々のデータ更新に関する手順は、  
「Microsoft 365 テナント全体の利用状況可視化サンプル利用ガイド」の[利用開始手順](../010_%E3%83%86%E3%83%8A%E3%83%B3%E3%83%88%E3%81%AE%E5%88%A9%E7%94%A8%E7%8A%B6%E6%B3%81%E5%8F%AF%E8%A6%96%E5%8C%96%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB/README.md#-%E5%88%A9%E7%94%A8%E9%96%8B%E5%A7%8B%E6%89%8B%E9%A0%86) 以降をご確認ください。

## 🔄 M365名簿の更新方法

> [!IMPORTANT]
> **年度の切り替わりにおける対応**  
> 年度が切り替わる場合、M365名簿を新規作成してSharePoint Online サイトに追加する必要があります。  
> SharePoint Online サイトに「school_year=yyyy」フォルダを作成し、新年度の情報を記載したM365名簿を格納してください。
> 
> 例）  2026年度になったら、Share Point Online サイトに「school_year=2026」というフォルダを新規作成します。  
> 　　 2026年度のM365名簿「2026-04-01_M365名簿.xlsx」も新規作成し、「school_year=2026」フォルダに格納します。
> 
> |<img src="images/Update_Roster_1.jpg" width="600">|
> |---------|
>
> 操作手順は上述「事前準備」の以下の手順を参考にしてください。
> + [1. M365名簿の作成](#1-M365名簿の作成)
> + [2. M365名簿の格納場所の準備](#2-M365名簿の格納場所の準備)
> + [3. M365名簿のアップロード](#3-M365名簿のアップロード)
>
> **※本システム運用開始時の留意点**  
> 本システム運用開始時には過去26日分のデータが読み込まれます。  
> それらのデータを分析対象としたい場合は、該当時点のM365名簿が必要になります。
> 
> **※M365名簿が存在しない場合のエラー表示**   
> 集計対象の年度のM365名簿が存在しない場合、レポート画面にエラーが表示されます。  
> エラーが表示された場合は、M365名簿がSharePoint Online サイトに登録されていることを確認してください。
> 
> |<img src="images/Roster_Error_1.jpg" width="600">|
> |---------|

> [!NOTE]
> **転出入等の対応**  
> 転出入等の事由により年度の途中でM365名簿の情報に変更が生じた場合は、M365名簿を新規作成することでレポートに反映することができます。  
> ただし、レポートへの反映が不要な場合は作業する必要はありません。  
>
> 新規作成したM365名簿は、Share Point Online サイトの「school_year=yyyy」フォルダに格納してください。
> 
> 例）  2025年4月1日に「2025-04-01_M365名簿.xlsx」を作成している状態で、2025年9月1日に児童生徒の転出入があった場合、  
> 　　 別途「2025-09-01_M365名簿.xlsx」を作成し、Share Point Online サイトの「school_year=2025」フォルダに追加します。
> 
> |<img src="images/Update_Roster_2.jpg" width="600">|
> |---------|

## ⚠ 注意事項

> [!CAUTION]
> + データを取り込んだレポートファイル (.pbix) は第三者に共有しないでください。含まれる情報が意図せず閲覧されてしまいます。

## 📚 関連情報

本プロジェクトに関連するドキュメント

- [Power BI Desktop のインストールガイド（Power BI Desktop の取得 - Power BI | Microsoft Learn）<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/fundamentals/desktop-get-the-desktop)
- [Power BI Desktop の起動に関する問題を解決する - Power BI | Microsoft Learn<img src="images/link-external.svg">](https://learn.microsoft.com/ja-jp/power-bi/connect-data/desktop-error-launching-desktop)

[Back to top](#top)
