# 公開先と配布

公開先は https://github.com/Hamzimer/Mac-Systemo-Monitor です。

ソース、3言語のREADME、実装画面プレビュー、アイコン、回帰チェックを収録しています。UIは日本語・英語・繁体中国語に切り替えできます。ライセンスはMITです。

`release-assets` に確認済みの5.1.4のDMGとSHA-256チェックサムを収録しています。GitHub Actionsの「Publish prepared release」は、この2ファイルの更新を受けてチェックサムを検証し、v5.1.4のReleaseへ公開します。リリースが存在する場合は処理を停止し、既存アセットを上書きしません。

ローカルビルドは `bash build.sh ./build`、回帰チェックは `bash tests/run.sh` です。

Developer ID署名・公証、実際のマウス操作による手動GUI検証は未完了です。詳細はREADMEをご覧ください。
